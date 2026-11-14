import 'dart:async';

import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_chat_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_chat.dart';
import 'package:signalr_hub/signalr_client.dart';

/// REST repository for 1-1 Mentor<->Learner threads & message history.
abstract interface class MentorChatRepository {
  Future<List<MentorChatThread>> loadThreads();

  Future<MentorChatThread> loadThread(int bookingId);

  Future<List<MentorChatMessage>> loadMessages(
    int bookingId, {
    int? beforeMessageId,
    int pageSize = 50,
  });

  Future<void> markRead(int bookingId);
}

class ApiMentorChatRepository implements MentorChatRepository {
  const ApiMentorChatRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MentorChatThread>> loadThreads() async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorChatThreads,
    );
    return readMentorEnvelopeList(response.data)
        .map(MentorChatThreadDto.fromJson)
        .toList(growable: false);
  }

  @override
  Future<MentorChatThread> loadThread(int bookingId) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorChatThread(bookingId),
    );
    return MentorChatThreadDto.fromJson(readMentorEnvelopeObject(response.data));
  }

  @override
  Future<List<MentorChatMessage>> loadMessages(
    int bookingId, {
    int? beforeMessageId,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get<Object?>(
      MentorApiPaths.mentorChatMessages(bookingId),
      queryParameters: {
        'pageSize': pageSize,
        if (beforeMessageId != null && beforeMessageId > 0)
          'beforeMessageId': beforeMessageId,
      },
    );
    return readMentorEnvelopeList(response.data)
        .map(MentorChatMessageDto.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markRead(int bookingId) async {
    await _apiClient.post<Object?>(MentorApiPaths.mentorChatRead(bookingId));
  }
}

/// Abstract SignalR client for `/hubs/mentor-chat` enabling clean testing.
abstract interface class MentorChatRealtimeClient {
  Stream<MentorChatConnectionStatus> get connectionStates;
  Stream<MentorChatMessage> get incomingMessages;
  Stream<int> get readReceipts;

  Future<void> connectAndJoin(int bookingId);
  Future<void> sendMessage(int bookingId, String text);
  Future<void> markRead(int bookingId);
  Future<void> leave(int bookingId);
  Future<void> dispose();
}

/// SignalR implementation of `/hubs/mentor-chat`.
class SignalRMentorChatClient implements MentorChatRealtimeClient {
  SignalRMentorChatClient({required this.hubUri, required this.tokenStorage});

  final Uri hubUri;
  final TokenStorage tokenStorage;

  final StreamController<MentorChatConnectionStatus> _stateController =
      StreamController<MentorChatConnectionStatus>.broadcast(sync: true);
  final StreamController<MentorChatMessage> _messageController =
      StreamController<MentorChatMessage>.broadcast(sync: true);
  final StreamController<int> _readController =
      StreamController<int>.broadcast(sync: true);

  HubConnection? _hub;
  int? _joinedBookingId;
  bool _disposed = false;
  bool _leaving = false;

  @override
  Stream<MentorChatConnectionStatus> get connectionStates =>
      _stateController.stream;

  @override
  Stream<MentorChatMessage> get incomingMessages => _messageController.stream;

  @override
  Stream<int> get readReceipts => _readController.stream;

  @override
  Future<void> connectAndJoin(int bookingId) async {
    if (_disposed) return;
    _leaving = false;
    _joinedBookingId = bookingId;
    _emitState(MentorChatConnectionStatus.connecting);

    final existing = _hub;
    if (existing != null) {
      try {
        await existing.stop();
      } catch (_) {}
      _hub = null;
    }

    try {
      final token = await tokenStorage.readAccessToken();
      if (token == null || token.trim().isEmpty) {
        _emitState(MentorChatConnectionStatus.failed);
        return;
      }

      final hub = HubConnectionBuilder()
          .withUrl(
            hubUri.toString(),
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  (await tokenStorage.readAccessToken()) ?? '',
              requestTimeout: 10000,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: const [0, 2000, 5000, 10000, 30000],
          )
          .build();
      hub.invocationTimeout = const Duration(seconds: 15);
      _hub = hub;
      _registerHandlers(hub);
      await hub.start();
      await hub.invoke('JoinBookingChat', args: [bookingId]);
      _emitState(MentorChatConnectionStatus.connected);
    } catch (_) {
      _emitState(MentorChatConnectionStatus.failed);
      rethrow;
    }
  }

  void _registerHandlers(HubConnection hub) {
    hub.on('ReceiveMentorChatMessage', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final first = arguments.first;
      if (first is! Map<Object?, Object?>) return;
      try {
        final msg = MentorChatMessageDto.fromJson(
          first.map((key, value) => MapEntry(key.toString(), value)),
        );
        if (!_messageController.isClosed) {
          _messageController.add(msg);
        }
      } catch (_) {}
    });

    hub.on('MentorChatRead', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      final bookingId = switch (raw) {
        int v => v,
        num v => v.toInt(),
        String s => int.tryParse(s),
        _ => null,
      };
      if (bookingId != null && bookingId > 0 && !_readController.isClosed) {
        _readController.add(bookingId);
      }
    });

    hub.onreconnecting(({error}) {
      if (_leaving || _disposed) return;
      _emitState(MentorChatConnectionStatus.reconnecting);
    });

    hub.onreconnected(({connectionId}) {
      if (_leaving || _disposed) return;
      final bookingId = _joinedBookingId;
      if (bookingId != null) {
        unawaited(_rejoin(bookingId));
      }
    });

    hub.onclose(({error}) {
      if (_leaving || _disposed) return;
      _emitState(MentorChatConnectionStatus.failed);
    });
  }

  Future<void> _rejoin(int bookingId) async {
    final hub = _hub;
    if (hub == null || _leaving || _disposed) return;
    try {
      await hub.invoke('JoinBookingChat', args: [bookingId]);
      _emitState(MentorChatConnectionStatus.connected);
    } catch (_) {
      _emitState(MentorChatConnectionStatus.failed);
    }
  }

  @override
  Future<void> sendMessage(int bookingId, String text) async {
    final hub = _hub;
    if (hub == null) {
      throw StateError('Chat hub is not connected.');
    }
    await hub.invoke(
      'SendChatMessage',
      args: [
        bookingId,
        {'text': text},
      ],
    );
  }

  @override
  Future<void> markRead(int bookingId) async {
    final hub = _hub;
    if (hub == null) return;
    await hub.invoke('MarkRead', args: [bookingId]);
  }

  @override
  Future<void> leave(int bookingId) async {
    _leaving = true;
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      try {
        await hub.invoke('LeaveBookingChat', args: [bookingId]);
      } catch (_) {}
      try {
        await hub.stop();
      } catch (_) {}
    }
    _emitState(MentorChatConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    final bookingId = _joinedBookingId;
    if (bookingId != null) {
      await leave(bookingId);
    }
    await _stateController.close();
    await _messageController.close();
    await _readController.close();
  }

  void _emitState(MentorChatConnectionStatus status) {
    if (!_stateController.isClosed) {
      _stateController.add(status);
    }
  }
}
