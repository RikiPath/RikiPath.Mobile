import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_chat_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_chat.dart';

final mentorChatRepositoryProvider = Provider<MentorChatRepository>(
  (ref) => ApiMentorChatRepository(ref.watch(apiClientProvider)),
);

final mentorChatRealtimeClientFactoryProvider =
    Provider<MentorChatRealtimeClient Function()>((ref) {
      return () {
        final config = ref.read(appConfigProvider);
        final tokenStorage = ref.read(tokenStorageProvider);
        final hubUri = config.apiBaseUrl.resolve(MentorApiPaths.mentorChatHub);
        return SignalRMentorChatClient(
          hubUri: hubUri,
          tokenStorage: tokenStorage,
        );
      };
    });

final mentorChatThreadsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MentorChatThreadsController,
      List<MentorChatThread>
    >(MentorChatThreadsController.new);

class MentorChatThreadsController extends AsyncNotifier<List<MentorChatThread>> {
  @override
  Future<List<MentorChatThread>> build() async {
    ref.watch(authenticatedUserIdProvider);
    final threads = await ref.watch(mentorChatRepositoryProvider).loadThreads();
    final sorted = [...threads]
      ..sort((a, b) {
        final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
        if (unreadCompare != 0) return unreadCompare;
        final aTime = a.lastMessage?.sentAt.value ?? a.scheduledAt?.value;
        final bTime = b.lastMessage?.sentAt.value ?? b.scheduledAt?.value;
        if (aTime == null && bTime == null) return b.bookingId.compareTo(a.bookingId);
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    return sorted;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class MentorChatRoomState {
  const MentorChatRoomState({
    required this.thread,
    required this.messages,
    required this.connectionStatus,
    this.hasMoreOlder = true,
    this.isLoadingOlder = false,
    this.isSending = false,
  });

  final MentorChatThread thread;
  final List<MentorChatMessage> messages;
  final MentorChatConnectionStatus connectionStatus;
  final bool hasMoreOlder;
  final bool isLoadingOlder;
  final bool isSending;

  MentorChatRoomState copyWith({
    MentorChatThread? thread,
    List<MentorChatMessage>? messages,
    MentorChatConnectionStatus? connectionStatus,
    bool? hasMoreOlder,
    bool? isLoadingOlder,
    bool? isSending,
  }) {
    return MentorChatRoomState(
      thread: thread ?? this.thread,
      messages: messages ?? this.messages,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
    );
  }
}

final mentorChatRoomControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MentorChatRoomController, MentorChatRoomState, int>(
      MentorChatRoomController.new,
    );

class MentorChatRoomController extends AsyncNotifier<MentorChatRoomState> {
  MentorChatRoomController(this.bookingId);

  final int bookingId;
  static const int _pageSize = 50;

  MentorChatRealtimeClient? _client;
  StreamSubscription<MentorChatConnectionStatus>? _statusSub;
  StreamSubscription<MentorChatMessage>? _messageSub;
  StreamSubscription<int>? _readSub;

  @override
  Future<MentorChatRoomState> build() async {
    ref.watch(authenticatedUserIdProvider);
    final repo = ref.watch(mentorChatRepositoryProvider);

    ref.onDispose(() {
      unawaited(_cleanupRealtime());
    });

    final threadFuture = repo.loadThread(bookingId);
    final messagesFuture = repo.loadMessages(bookingId, pageSize: _pageSize);
    final thread = await threadFuture;
    final messages = await messagesFuture;
    final ordered = _sortChronological(messages);

    unawaited(_markReadAndRefreshList());
    unawaited(_connectRealtime(thread.bookingId));

    return MentorChatRoomState(
      thread: thread,
      messages: ordered,
      connectionStatus: MentorChatConnectionStatus.connecting,
      hasMoreOlder: messages.length >= _pageSize,
    );
  }

  Future<void> _connectRealtime(int canonicalBookingId) async {
    try {
      final client = ref.read(mentorChatRealtimeClientFactoryProvider)();
      _client = client;
      _statusSub = client.connectionStates.listen((status) {
        final current = state.asData?.value;
        if (current != null) {
          state = AsyncData(current.copyWith(connectionStatus: status));
        }
      });
      _messageSub = client.incomingMessages.listen((msg) {
        if (msg.bookingId != canonicalBookingId && msg.bookingId != bookingId) {
          return;
        }
        final current = state.asData?.value;
        if (current == null) return;
        if (current.messages.any((m) => m.id == msg.id)) return;
        final updated = _sortChronological([...current.messages, msg]);
        state = AsyncData(
          current.copyWith(
            messages: updated,
            thread: current.thread.copyWith(lastMessage: msg, unreadCount: 0),
          ),
        );
        unawaited(_markReadAndRefreshList());
      });
      _readSub = client.readReceipts.listen((readBookingId) {
        if (readBookingId != canonicalBookingId && readBookingId != bookingId) {
          return;
        }
        final current = state.asData?.value;
        if (current == null) return;
        state = AsyncData(
          current.copyWith(thread: current.thread.copyWith(unreadCount: 0)),
        );
      });
      await client.connectAndJoin(canonicalBookingId);
    } catch (_) {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            connectionStatus: MentorChatConnectionStatus.failed,
          ),
        );
      }
    }
  }

  Future<void> _cleanupRealtime() async {
    await _statusSub?.cancel();
    await _messageSub?.cancel();
    await _readSub?.cancel();
    _statusSub = null;
    _messageSub = null;
    _readSub = null;
    final client = _client;
    _client = null;
    if (client != null) {
      await client.dispose();
    }
  }

  Future<void> _markReadAndRefreshList() async {
    final repo = ref.read(mentorChatRepositoryProvider);
    try {
      final client = _client;
      if (client != null &&
          state.asData?.value.connectionStatus ==
              MentorChatConnectionStatus.connected) {
        await client.markRead(bookingId);
      } else {
        await repo.markRead(bookingId);
      }
      ref.invalidate(mentorChatThreadsControllerProvider);
    } catch (_) {}
  }

  Future<void> loadOlder() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMoreOlder ||
        current.isLoadingOlder ||
        current.messages.isEmpty) {
      return;
    }
    final oldestId = current.messages.first.id;
    state = AsyncData(current.copyWith(isLoadingOlder: true));
    try {
      final older = await ref.read(mentorChatRepositoryProvider).loadMessages(
            bookingId,
            beforeMessageId: oldestId,
            pageSize: _pageSize,
          );
      final existingIds = current.messages.map((m) => m.id).toSet();
      final combined = _sortChronological([
        ...older.where((m) => !existingIds.contains(m.id)),
        ...current.messages,
      ]);
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          messages: combined,
          hasMoreOlder: older.length >= _pageSize,
          isLoadingOlder: false,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(isLoadingOlder: false));
      rethrow;
    }
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;
    final current = state.asData?.value;
    if (current == null || !current.thread.canSendMessages) {
      throw StateError('Cuộc trò chuyện hiện đang ở chế độ chỉ đọc.');
    }
    state = AsyncData(current.copyWith(isSending: true));
    try {
      var client = _client;
      if (client == null ||
          current.connectionStatus != MentorChatConnectionStatus.connected) {
        await _cleanupRealtime();
        await _connectRealtime(current.thread.bookingId);
        client = _client;
      }
      if (client == null) {
        throw StateError('Chưa kết nối được máy chủ trò chuyện.');
      }
      await client.sendMessage(current.thread.bookingId, text);
      // Reload latest messages in case Hub broadcast arrived after invoke or reconnect.
      final latestMessages = await ref
          .read(mentorChatRepositoryProvider)
          .loadMessages(bookingId, pageSize: _pageSize);
      final latestState = state.asData?.value ?? current;
      final mergedMap = <int, MentorChatMessage>{
        for (final m in latestState.messages) m.id: m,
        for (final m in latestMessages) m.id: m,
      };
      final merged = _sortChronological(mergedMap.values.toList());
      state = AsyncData(
        latestState.copyWith(
          messages: merged,
          isSending: false,
          thread: merged.isNotEmpty
              ? latestState.thread.copyWith(lastMessage: merged.last)
              : latestState.thread,
        ),
      );
      ref.invalidate(mentorChatThreadsControllerProvider);
    } catch (_) {
      final latestState = state.asData?.value ?? current;
      state = AsyncData(latestState.copyWith(isSending: false));
      rethrow;
    }
  }

  Future<void> reconnect() async {
    final current = state.asData?.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    await _cleanupRealtime();
    await _connectRealtime(current.thread.bookingId);
    final refreshed = await ref
        .read(mentorChatRepositoryProvider)
        .loadMessages(bookingId, pageSize: _pageSize);
    final latestState = state.asData?.value ?? current;
    final mergedMap = <int, MentorChatMessage>{
      for (final m in latestState.messages) m.id: m,
      for (final m in refreshed) m.id: m,
    };
    state = AsyncData(
      latestState.copyWith(
        messages: _sortChronological(mergedMap.values.toList()),
      ),
    );
  }

  static List<MentorChatMessage> _sortChronological(
    List<MentorChatMessage> items,
  ) {
    final copy = [...items];
    copy.sort((a, b) {
      final timeCompare = a.sentAt.value.compareTo(b.sentAt.value);
      return timeCompare != 0 ? timeCompare : a.id.compareTo(b.id);
    });
    return copy;
  }
}
