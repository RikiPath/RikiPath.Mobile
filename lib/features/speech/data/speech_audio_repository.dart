import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/speech/data/speech_api_paths.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_essay_writing_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

class SpeechAudioRepository {
  const SpeechAudioRepository(this._client);

  final ApiClient _client;

  Future<String> transcribeAudio({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'audioFile': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.post<Object?>(
      SpeechApiPaths.transcribe,
      data: form,
    );
    final body = response.data;
    if (body is Map) {
      final direct = body['text'];
      if (direct is String) return direct.trim();
      final result = body['result'] ?? body['data'];
      if (result is String) return result.trim();
    }
    throw const FormatException('Invalid Speech transcribe response.');
  }

  Future<EssayWritingResult> gradeAudio({
    required Uint8List bytes,
    required String fileName,
    required int certificateLevelId,
    String? topic,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'audioFile': MultipartFile.fromBytes(bytes, filename: fileName),
      'certificateLevelId': certificateLevelId,
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
    });
    final response = await _client.post<Object?>(
      SpeechApiPaths.grade,
      data: form,
    );
    return parseEssayWritingResult(response.data);
  }

  Future<EssayWritingResult> gradeTranscript({
    required int certificateLevelId,
    required String textContent,
    String? topic,
  }) async {
    final response = await _client.post<Object?>(
      '/api/PracticeSubmission/submit',
      data: <String, Object?>{
        'type': 'Speaking',
        'certificateLevelId': certificateLevelId,
        'textContent': textContent.trim(),
        if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
      },
    );
    return parseEssayWritingResult(response.data);
  }
}

final speechAudioRepositoryProvider = Provider<SpeechAudioRepository>(
  (ref) => SpeechAudioRepository(ref.watch(apiClientProvider)),
);
