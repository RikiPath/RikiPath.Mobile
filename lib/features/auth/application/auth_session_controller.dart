import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/domain/jwt_session_claims.dart';

final authSessionControllerProvider = Provider<AuthSessionController>((ref) {
  final controller = AuthSessionController(ref.watch(tokenStorageProvider));
  ref.onDispose(controller.dispose);
  unawaited(controller.restore());
  return controller;
});

/// Reactive identity key for owner-scoped providers without changing the
/// existing session controller's public provider contract.
final authenticatedUserIdProvider = Provider<int?>((ref) {
  final session = ref.watch(authSessionControllerProvider);
  void onSessionChanged() => ref.invalidateSelf();
  session.addListener(onSessionChanged);
  ref.onDispose(() => session.removeListener(onSessionChanged));
  return session.currentUserId;
});

enum AuthSessionState { unknown, unauthenticated, authenticated }

class AuthSessionController extends ValueNotifier<AuthSessionState> {
  AuthSessionController(
    this._tokenStorage, {
    AuthSessionState initialState = AuthSessionState.unknown,
    int? initialUserId,
    BackendUserRole? initialRole,
  }) : _currentUserId = initialUserId,
       _currentRole = initialRole,
       super(initialState);

  final TokenStorage _tokenStorage;
  int? _currentUserId;
  BackendUserRole? _currentRole;
  int _operation = 0;
  bool _isDisposed = false;

  int? get currentUserId => _currentUserId;
  BackendUserRole? get currentRole => _currentRole;

  Future<void> restore() async {
    final operation = ++_operation;
    AuthSessionState restoredState;
    int? restoredUserId;
    BackendUserRole? restoredRole;

    try {
      final token = await _tokenStorage.readAccessToken();
      final userId = await _tokenStorage.readAuthenticatedUserId();
      final storedRole = await _tokenStorage.readAuthenticatedRole();
      restoredRole = storedRole == null
          ? null
          : BackendUserRole.fromApiValue(storedRole);
      final claims = token == null || token.trim().isEmpty
          ? null
          : JwtSessionClaims.parse(token);
      restoredState =
          claims == null ||
              userId == null ||
              userId <= 0 ||
              restoredRole == null ||
              claims.userId != userId ||
              claims.role != restoredRole ||
              claims.isExpiredAt(DateTime.now().toUtc())
          ? AuthSessionState.unauthenticated
          : AuthSessionState.authenticated;
      if (restoredState == AuthSessionState.authenticated) {
        restoredUserId = userId;
      } else if (token != null || userId != null || storedRole != null) {
        await _tokenStorage.clear();
        restoredRole = null;
      }
    } catch (_) {
      restoredState = AuthSessionState.unauthenticated;
      restoredRole = null;
      try {
        await _tokenStorage.clear();
      } catch (_) {
        // The local session still fails closed even if secure-storage cleanup
        // is temporarily unavailable.
      }
    }

    if (_isDisposed || operation != _operation) return;
    _currentUserId = restoredUserId;
    _currentRole = restoredRole;
    value = restoredState;
  }

  void markAuthenticated({required int userId, required BackendUserRole role}) {
    _operation += 1;
    final identityChanged = _currentUserId != userId || _currentRole != role;
    _currentUserId = userId;
    _currentRole = role;
    if (value == AuthSessionState.authenticated) {
      if (identityChanged) notifyListeners();
    } else {
      value = AuthSessionState.authenticated;
    }
  }

  Future<void> signOut() async {
    final operation = ++_operation;
    _currentUserId = null;
    _currentRole = null;
    value = AuthSessionState.unknown;

    try {
      await _tokenStorage.clear();
    } finally {
      if (!_isDisposed && operation == _operation) {
        value = AuthSessionState.unauthenticated;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
