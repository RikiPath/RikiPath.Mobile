import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/config/app_env.dart';

void main() {
  group('AppConfig', () {
    test('uses compile-time overrides or safe development defaults', () {
      const expectedEnvironment = String.fromEnvironment(
        'APP_ENV',
        defaultValue: AppConfig.defaultDevelopmentEnvironment,
      );
      const expectedApiBaseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: AppConfig.defaultDevelopmentApiBaseUrl,
      );
      const expectedSwaggerUrl = String.fromEnvironment(
        'SWAGGER_URL',
        defaultValue: AppConfig.defaultDevelopmentSwaggerUrl,
      );
      const expectedApiLogging = String.fromEnvironment(
        'ENABLE_API_LOGGING',
        defaultValue: AppConfig.defaultDevelopmentApiLogging,
      );

      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnv.parse(expectedEnvironment));
      expect(config.apiBaseUrl, Uri.parse(expectedApiBaseUrl));
      expect(config.swaggerUrl, Uri.parse(expectedSwaggerUrl));
      expect(config.enableApiLogging, expectedApiLogging == 'true');
    });

    test('accepts an explicit non-development configuration', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'staging',
        'API_BASE_URL': 'https://staging.example.com',
        'SWAGGER_URL': 'https://staging.example.com/swagger/index.html',
        'ENABLE_API_LOGGING': 'false',
      });

      expect(config.environment, AppEnv.staging);
      expect(config.apiBaseUrl, Uri.parse('https://staging.example.com'));
      expect(
        config.swaggerUrl,
        Uri.parse('https://staging.example.com/swagger/index.html'),
      );
      expect(config.enableApiLogging, isFalse);
      expect(config.shouldLogApi, isFalse);
    });

    test('keeps strict validation for explicitly supplied values', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'production',
          'API_BASE_URL': 'http://production.example.com',
          'SWAGGER_URL': 'https://production.example.com/swagger/index.html',
          'ENABLE_API_LOGGING': 'false',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
