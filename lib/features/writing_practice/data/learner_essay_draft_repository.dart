import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

@immutable
class LearnerEssayListItem {
  const LearnerEssayListItem({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.scannedAt,
    this.previewText = '',
  });

  factory LearnerEssayListItem.fromJson(Map<String, Object?> json) {
    final scanned = json['scannedAt'];
    return LearnerEssayListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      scannedAt: scanned is String ? DateTime.tryParse(scanned) : null,
      previewText: json['previewText'] as String? ?? '',
    );
  }

  final int id;
  final String title;
  final String imageUrl;
  final DateTime? scannedAt;
  final String previewText;
}

@immutable
class LearnerEssayDetail {
  const LearnerEssayDetail({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.originalOcrText = '',
    required this.contentText,
    this.scannedAt,
    this.modifiedAt,
  });

  factory LearnerEssayDetail.fromJson(Map<String, Object?> json) {
    final scanned = json['scannedAt'];
    final modified = json['modifiedAt'];
    return LearnerEssayDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      originalOcrText: json['originalOcrText'] as String? ?? '',
      contentText: json['contentText'] as String? ?? '',
      scannedAt: scanned is String ? DateTime.tryParse(scanned) : null,
      modifiedAt: modified is String ? DateTime.tryParse(modified) : null,
    );
  }

  final int id;
  final String title;
  final String imageUrl;
  final String originalOcrText;
  final String contentText;
  final DateTime? scannedAt;
  final DateTime? modifiedAt;
}

class LearnerEssayDraftRepository {
  const LearnerEssayDraftRepository(this._client);

  final ApiClient _client;

  Future<List<LearnerEssayListItem>> listDrafts() async {
    final response = await _client.get<Object?>('/api/learner-essays');
    final raw = _extractEnvelope(response.data);
    if (raw is! List) return const <LearnerEssayListItem>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => LearnerEssayListItem.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }

  Future<LearnerEssayDetail> getDraft(int id) async {
    final response = await _client.get<Object?>('/api/learner-essays/$id');
    return LearnerEssayDetail.fromJson(_extractObject(response.data));
  }

  Future<LearnerEssayDetail> createDraft({
    required String contentText,
    String? originalOcrText,
    Uint8List? imageBytes,
    String? fileName,
    String? contentType,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'ContentText': contentText,
      if (originalOcrText != null && originalOcrText.isNotEmpty)
        'OriginalOcrText': originalOcrText,
      if (imageBytes != null && fileName != null && contentType != null)
        'Image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
    });
    final response = await _client.post<Object?>(
      '/api/learner-essays',
      data: form,
    );
    return LearnerEssayDetail.fromJson(_extractObject(response.data));
  }

  Future<LearnerEssayDetail> updateDraftContent(
    int id,
    String contentText,
  ) async {
    final response = await _client.put<Object?>(
      '/api/learner-essays/$id',
      data: <String, Object?>{'contentText': contentText},
    );
    return LearnerEssayDetail.fromJson(_extractObject(response.data));
  }

  Future<String> rescanDraft(
    int id, {
    required Uint8List imageBytes,
    required String fileName,
    required String contentType,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'Image': MultipartFile.fromBytes(
        imageBytes,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    final response = await _client.post<Object?>(
      '/api/learner-essays/$id/rescan',
      data: form,
    );
    final obj = _extractObject(response.data);
    return (obj['text'] as String? ?? '').trim();
  }

  Future<void> deleteDraft(int id) async {
    await _client.delete<Object?>('/api/learner-essays/$id');
  }

  static Object? _extractEnvelope(Object? body) {
    if (body is Map) return body['result'] ?? body['data'];
    return body;
  }

  static Map<String, Object?> _extractObject(Object? body) {
    final inner = _extractEnvelope(body);
    if (inner is Map) {
      return inner.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const FormatException('Expected essay JSON object.');
  }
}

final learnerEssayDraftRepositoryProvider =
    Provider<LearnerEssayDraftRepository>(
      (ref) => LearnerEssayDraftRepository(ref.watch(apiClientProvider)),
    );

final learnerEssayDraftsProvider =
    FutureProvider.autoDispose<List<LearnerEssayListItem>>((ref) async {
      ref.watch(authenticatedUserIdProvider);
      return ref.watch(learnerEssayDraftRepositoryProvider).listDrafts();
    });
