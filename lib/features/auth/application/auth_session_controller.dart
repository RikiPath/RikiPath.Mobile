import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';

final authSessionControllerProvider = Provider<AuthSessionController>((ref) {
  final controller = AuthSessionController(ref.watch(tokenStorageProvider));
  ref.onDispose(controller.dispose);
  unawaited(controller.restore());
  return controller;
});

enum AuthSessionState { unknown, unauthenticated, authenticated }

class AuthSessionController extends ValueNotifier<AuthSessionState> {
  AuthSessionController(
    this._tokenStorage, {
    AuthSessionState initialState = AuthSessionState.unknown,
  }) : super(initialState);

  final TokenStorage _tokenStorage;
  int _operation = 0;
  bool _isDisposed = false;

  Future<void> restore() async {
    final operation = ++_operation;
    AuthSessionState restoredState;

    try {
      final token = await _tokenStorage.readAccessToken();
      restoredState = token == null || token.trim().isEmpty
          ? AuthSessionState.unauthenticated
          : AuthSessionState.authenticated;
    } catch (_) {
      restoredState = AuthSessionState.unauthenticated;
    }

    if (_isDisposed || operation != _operation) return;
    value = restoredState;
  }

  void markAuthenticated() {
    _operation += 1;
    value = AuthSessionState.authenticated;
  }

  Future<void> signOut() async {
    final operation = ++_operation;
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
