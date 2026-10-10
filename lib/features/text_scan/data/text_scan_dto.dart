import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

class TextScanResultDto {
  const TextScanResultDto({required this.text, this.scannedAt});

  factory TextScanResultDto.fromEnvelope(Object? body) {
    if (body is! Map<Object?, Object?> || body['isSuccess'] != true) {
      throw const FormatException('Expected a successful scan envelope.');
    }
    final result = body['result'];
    if (result is! Map<Object?, Object?>) {
      throw const FormatException('Expected a scan result object.');
    }
    final text = result['text'];
    if (text is! String) {
      throw const FormatException('Expected a scan text field.');
    }
    final rawScannedAt = result['scannedAt'];
    final scannedAt = switch (rawScannedAt) {
      String value => DateTime.tryParse(value),
      null => null,
      _ => throw const FormatException('Expected a scan timestamp field.'),
    };
    if (rawScannedAt is String && scannedAt == null) {
      throw const FormatException('Expected a valid scan timestamp.');
    }
    return TextScanResultDto(text: text.trim(), scannedAt: scannedAt);
  }

  final String text;
  final DateTime? scannedAt;

  TextScanResult toDomain() => TextScanResult(text: text, scannedAt: scannedAt);
}
