import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/config/app_env.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig must be provided during application bootstrap.');
});

class AppConfig {
  static const String defaultDevelopmentEnvironment = 'development';
  static const String defaultDevelopmentApiBaseUrl =
      'https://fact-like-tracy-displays.trycloudflare.com';
  static const String defaultDevelopmentSwaggerUrl =
      'https://fact-like-tracy-displays.trycloudflare.com/swagger/index.html';
  static const String defaultDevelopmentApiLogging = 'true';

  static const String _undefinedDartDefine =
      '__RIKIPATH_UNDEFINED_DART_DEFINE__';

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.swaggerUrl,
    required this.enableApiLogging,
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: defaultDevelopmentEnvironment,
    );
    const apiBaseUrlValue = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _undefinedDartDefine,
    );
    const swaggerUrlValue = String.fromEnvironment(
      'SWAGGER_URL',
      defaultValue: _undefinedDartDefine,
    );
    const apiLoggingValue = String.fromEnvironment(
      'ENABLE_API_LOGGING',
      defaultValue: _undefinedDartDefine,
    );
    final environment = AppEnv.parse(environmentValue);

    return AppConfig.fromValues({
      'APP_ENV': environmentValue,
      'API_BASE_URL': _resolveDartDefine(
        apiBaseUrlValue,
        environment: environment,
        developmentDefault: defaultDevelopmentApiBaseUrl,
      ),
      'SWAGGER_URL': _resolveDartDefine(
        swaggerUrlValue,
        environment: environment,
        developmentDefault: defaultDevelopmentSwaggerUrl,
      ),
      'ENABLE_API_LOGGING': _resolveDartDefine(
        apiLoggingValue,
        environment: environment,
        developmentDefault: defaultDevelopmentApiLogging,
      ),
    });
  }

  factory AppConfig.fromValues(Map<String, String> values) {
    final environment = AppEnv.parse(_required(values, 'APP_ENV'));
    final apiBaseUrl = _absoluteHttpUri(
      _required(values, 'API_BASE_URL'),
      name: 'API_BASE_URL',
      originOnly: true,
    );
    final swaggerUrl = _absoluteHttpUri(
      _required(values, 'SWAGGER_URL'),
      name: 'SWAGGER_URL',
    );
    final enableApiLogging = _boolean(
      _required(values, 'ENABLE_API_LOGGING'),
      name: 'ENABLE_API_LOGGING',
    );

    if (environment.isProduction && apiBaseUrl.scheme != 'https') {
      throw const FormatException('Production API_BASE_URL must use HTTPS.');
    }
    if (environment.isProduction && enableApiLogging) {
      throw const FormatException(
        'ENABLE_API_LOGGING must be false in production.',
      );
    }

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      swaggerUrl: swaggerUrl,
      enableApiLogging: enableApiLogging,
    );
  }

  final AppEnv environment;
  final Uri apiBaseUrl;
  final Uri swaggerUrl;
  final bool enableApiLogging;

  bool get shouldLogApi =>
      environment == AppEnv.development && enableApiLogging;

  static String _resolveDartDefine(
    String value, {
    required AppEnv environment,
    required String developmentDefault,
  }) {
    if (value != _undefinedDartDefine) return value;
    return environment == AppEnv.development ? developmentDefault : '';
  }

  static String _required(Map<String, String> values, String name) {
    final value = values[name]?.trim() ?? '';
    if (value.isEmpty) {
      throw FormatException('$name is required.');
    }
    return value;
  }

  static Uri _absoluteHttpUri(
    String value, {
    required String name,
    bool originOnly = false,
  }) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw FormatException('$name must be an absolute HTTP(S) URL.');
    }
    if (originOnly && uri.path.isNotEmpty && uri.path != '/') {
      throw FormatException(
        '$name must contain only the deployment origin, without /api or '
        'Swagger paths.',
      );
    }

    return originOnly && uri.path == '/' ? uri.replace(path: '') : uri;
  }

  static bool _boolean(String value, {required String name}) {
    return switch (value.trim().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw FormatException('$name must be true or false.'),
    };
  }
}
