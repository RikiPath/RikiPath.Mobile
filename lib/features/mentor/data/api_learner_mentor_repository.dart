import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_repository.dart';

class ApiLearnerMentorRepository implements LearnerMentorRepository {
  const ApiLearnerMentorRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<BookableMentor>> loadMentors() async {
    final response = await _apiClient.get<Object?>(
      LearnerMentorApiPaths.mentors,
    );
    return readLearnerMentorResultList(response.data)
        .map(BookableMentorDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList(growable: false);
  }
}
