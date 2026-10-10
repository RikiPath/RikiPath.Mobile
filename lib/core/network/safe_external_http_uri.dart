Uri? parseSafeExternalHttpUri(String? rawValue) {
  final normalized = rawValue?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  return uri;
}
