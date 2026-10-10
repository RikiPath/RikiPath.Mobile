import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/speech/data/speech_api_paths.dart';
import 'package:rikipath_mobile/features/speech/data/speech_token_dto.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

class ApiSpeechTokenRepository implements SpeechTokenRepository {
  const ApiSpeechTokenRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<SpeechToken> issueToken() async {
    final response = await _apiClient.get<Object?>(SpeechApiPaths.token);
    try {
      return SpeechTokenDto.fromEnvelope(response.data).toDomain();
    } on FormatException {
      throw const UnknownError(
        message: 'The Speech token response is malformed.',
      );
    }
  }
}
