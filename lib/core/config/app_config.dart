import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/config/app_env.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig must be provided during application bootstrap.');
});

enum ApiProfile {
  localEmulator,
  remote;

  static ApiProfile parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'local-emulator' => ApiProfile.localEmulator,
      'remote' => ApiProfile.remote,
      _ => throw const FormatException(
        'API_PROFILE must be local-emulator or remote.',
      ),
    };
  }
}

class AppConfig {
  static const String defaultDevelopmentEnvironment = 'development';
  static const String localEmulatorApiBaseUrl =
      'http://10.0.2.2:5265';
  static const String localEmulatorSwaggerUrl =
      'http://10.0.2.2:5265/swagger/index.html';
  static const String localEmulatorApiLogging = 'true';
  static const String remoteApiLogging = 'false';

  static const String _undefinedDartDefine =
      '__RIKIPATH_UNDEFINED_DART_DEFINE__';

  const AppConfig({
    required this.environment,
    required this.apiProfile,
    required this.apiBaseUrl,
    required this.swaggerUrl,
    required this.enableApiLogging,
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: defaultDevelopmentEnvironment,
    );
    const apiProfileValue = String.fromEnvironment('API_PROFILE');
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
    final apiProfile = ApiProfile.parse(apiProfileValue);

    return AppConfig.fromValues({
      'APP_ENV': environmentValue,
      'API_PROFILE': apiProfileValue,
      'API_BASE_URL': _resolveDartDefine(
        apiBaseUrlValue,
        apiProfile: apiProfile,
        localDefault: localEmulatorApiBaseUrl,
      ),
      'SWAGGER_URL': _resolveDartDefine(
        swaggerUrlValue,
        apiProfile: apiProfile,
        localDefault: localEmulatorSwaggerUrl,
      ),
      'ENABLE_API_LOGGING': _resolveDartDefine(
        apiLoggingValue,
        apiProfile: apiProfile,
        localDefault: localEmulatorApiLogging,
        remoteDefault: remoteApiLogging,
      ),
    });
  }

  factory AppConfig.fromValues(Map<String, String> values) {
    final environment = AppEnv.parse(_required(values, 'APP_ENV'));
    final apiProfile = ApiProfile.parse(_required(values, 'API_PROFILE'));
    final apiBaseUrl = _absoluteHttpUri(
      _configuredValue(
        values,
        'API_BASE_URL',
        profile: apiProfile,
        localDefault: localEmulatorApiBaseUrl,
      ),
      name: 'API_BASE_URL',
      originOnly: true,
    );
    final swaggerUrl = _absoluteHttpUri(
      _configuredValue(
        values,
        'SWAGGER_URL',
        profile: apiProfile,
        localDefault: localEmulatorSwaggerUrl,
      ),
      name: 'SWAGGER_URL',
    );
    final enableApiLogging = _boolean(
      _configuredValue(
        values,
        'ENABLE_API_LOGGING',
        profile: apiProfile,
        localDefault: localEmulatorApiLogging,
        remoteDefault: remoteApiLogging,
      ),
      name: 'ENABLE_API_LOGGING',
    );

    if (apiProfile == ApiProfile.localEmulator) {
      if (environment != AppEnv.development) {
        throw const FormatException(
          'The local-emulator API profile is only valid in development.',
        );
      }
      if (apiBaseUrl.host != '10.0.2.2') {
        throw const FormatException(
          'The local-emulator API profile must target Android host alias 10.0.2.2.',
        );
      }
    } else {
      if (apiBaseUrl.scheme != 'https' || swaggerUrl.scheme != 'https') {
        throw const FormatException(
          'Remote API and Swagger endpoints must use HTTPS.',
        );
      }
      if (_isLocalHost(apiBaseUrl.host) || _isLocalHost(swaggerUrl.host)) {
        throw const FormatException(
          'The remote API profile cannot target a loopback or emulator host.',
        );
      }
    }

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
      apiProfile: apiProfile,
      apiBaseUrl: apiBaseUrl,
      swaggerUrl: swaggerUrl,
      enableApiLogging: enableApiLogging,
    );
  }

  final AppEnv environment;
  final ApiProfile apiProfile;
  final Uri apiBaseUrl;
  final Uri swaggerUrl;
  final bool enableApiLogging;

  bool get shouldLogApi =>
      environment == AppEnv.development && enableApiLogging;

  static String _resolveDartDefine(
    String value, {
    required ApiProfile apiProfile,
    String localDefault = '',
    String remoteDefault = '',
  }) {
    if (value != _undefinedDartDefine) return value;
    return apiProfile == ApiProfile.localEmulator
        ? localDefault
        : remoteDefault;
  }

  static String _configuredValue(
    Map<String, String> values,
    String name, {
    required ApiProfile profile,
    String localDefault = '',
    String remoteDefault = '',
  }) {
    final value = values[name]?.trim() ?? '';
    if (value.isNotEmpty) return value;
    if (profile == ApiProfile.localEmulator) return localDefault;
    if (remoteDefault.isNotEmpty) return remoteDefault;
    return _required(values, name);
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1' ||
        normalized == '10.0.2.2';
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
