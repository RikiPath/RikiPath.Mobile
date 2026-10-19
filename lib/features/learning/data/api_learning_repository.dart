import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/learning_api_paths.dart';
import 'package:rikipath_mobile/features/learning/data/learning_dtos.dart';
import 'package:rikipath_mobile/features/learning/data/learning_mapper.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

class ApiLearningRepository implements LearningRepository {
  const ApiLearningRepository(this._client);

  final ApiClient _client;

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) async {
    if (certificateLevelId <= 0) {
      throw ArgumentError.value(certificateLevelId, 'certificateLevelId');
    }
    final response = await _client.get<Object?>(
      LearningApiPaths.lessons,
      queryParameters: <String, dynamic>{
        'certificateLevelId': certificateLevelId,
      },
    );
    try {
      final snapshot = LearningMapper.discovery(
        readLearningDiscovery(response.data),
      );
      if (snapshot.certificateLevelId != certificateLevelId) {
        throw const FormatException('Mismatched JLPT level ID.');
      }
      return snapshot;
    } on FormatException {
      throw const UnknownError(
        message: 'The learning discovery response did not match the contract.',
      );
    }
  }
}
