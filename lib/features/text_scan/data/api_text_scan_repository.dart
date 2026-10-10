import 'package:dio/dio.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/text_scan/data/text_scan_api_paths.dart';
import 'package:rikipath_mobile/features/text_scan/data/text_scan_dto.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

class ApiTextScanRepository implements TextScanRepository {
  const ApiTextScanRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<TextScanResult> scan(TextScanImage image) async {
    final formData = FormData.fromMap(<String, Object?>{
      // Keep the exact source-backed ASP.NET request property name.
      'Image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.fileName,
        contentType: DioMediaType.parse(image.contentType),
      ),
    });
    final response = await _apiClient.post<Object?>(
      TextScanApiPaths.scan,
      data: formData,
    );
    try {
      return TextScanResultDto.fromEnvelope(response.data).toDomain();
    } on FormatException {
      throw const UnknownError(message: 'The OCR response is malformed.');
    }
  }
}
