import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/config/app_env.dart';

void main() {
  group('AppConfig', () {
    test('local emulator endpoint requires an explicit local profile', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'development',
        'API_PROFILE': 'local-emulator',
      });

      expect(config.apiProfile, ApiProfile.localEmulator);
      expect(config.apiBaseUrl, Uri.parse('http://10.0.2.2:5265'));
      expect(
        config.swaggerUrl,
        Uri.parse('http://10.0.2.2:5265/swagger/index.html'),
      );
      expect(config.enableApiLogging, isTrue);
      expect(config.shouldLogApi, isTrue);
    });

    test('remote profile requires explicit HTTPS endpoints and disables logging', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'development',
        'API_PROFILE': 'remote',
        'API_BASE_URL': 'https://test.example.invalid',
        'SWAGGER_URL': 'https://test.example.invalid/swagger/index.html',
      });

      expect(config.environment, AppEnv.development);
      expect(config.apiProfile, ApiProfile.remote);
      expect(config.apiBaseUrl, Uri.parse('https://test.example.invalid'));
      expect(
        config.swaggerUrl,
        Uri.parse('https://test.example.invalid/swagger/index.html'),
      );
      expect(config.enableApiLogging, isFalse);
      expect(config.shouldLogApi, isFalse);
    });

    test('remote profile rejects missing endpoint values', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'development',
          'API_PROFILE': 'remote',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('remote profile rejects emulator and loopback URLs', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'development',
          'API_PROFILE': 'remote',
          'API_BASE_URL': 'https://10.0.2.2:5265',
          'SWAGGER_URL': 'https://10.0.2.2:5265/swagger/index.html',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('local emulator profile is unavailable outside development', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'production',
          'API_PROFILE': 'local-emulator',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('production requires HTTPS and API logging disabled', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'production',
          'API_PROFILE': 'remote',
          'API_BASE_URL': 'https://api.example.invalid',
          'SWAGGER_URL': 'https://api.example.invalid/swagger/index.html',
          'ENABLE_API_LOGGING': 'true',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('requires a recognized API profile', () {
      expect(
        () => AppConfig.fromValues(const {
          'APP_ENV': 'development',
          'API_PROFILE': 'stale-tunnel',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('validates .env.local profile values correctly', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'development',
        'API_PROFILE': 'local-emulator',
        'API_BASE_URL': 'http://10.0.2.2:5265',
        'SWAGGER_URL': 'http://10.0.2.2:5265/swagger/index.html',
        'ENABLE_API_LOGGING': 'true',
      });

      expect(config.environment, AppEnv.development);
      expect(config.apiProfile, ApiProfile.localEmulator);
      expect(config.apiBaseUrl, Uri.parse('http://10.0.2.2:5265'));
      expect(
        config.swaggerUrl,
        Uri.parse('http://10.0.2.2:5265/swagger/index.html'),
      );
      expect(config.enableApiLogging, isTrue);
      expect(config.shouldLogApi, isTrue);
    });

    test('validates .env.development (Cloudflare remote) profile values correctly', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'development',
        'API_PROFILE': 'remote',
        'API_BASE_URL': 'https://fact-like-tracy-displays.trycloudflare.com',
        'SWAGGER_URL': 'https://fact-like-tracy-displays.trycloudflare.com/swagger/index.html',
        'ENABLE_API_LOGGING': 'true',
      });

      expect(config.environment, AppEnv.development);
      expect(config.apiProfile, ApiProfile.remote);
      expect(
        config.apiBaseUrl,
        Uri.parse('https://fact-like-tracy-displays.trycloudflare.com'),
      );
      expect(
        config.swaggerUrl,
        Uri.parse('https://fact-like-tracy-displays.trycloudflare.com/swagger/index.html'),
      );
      expect(config.enableApiLogging, isTrue);
      expect(config.shouldLogApi, isTrue);
    });

    test('remote profile does not fallback to local emulator host', () {
      final config = AppConfig.fromValues(const {
        'APP_ENV': 'development',
        'API_PROFILE': 'remote',
        'API_BASE_URL': 'https://fact-like-tracy-displays.trycloudflare.com',
        'SWAGGER_URL': 'https://fact-like-tracy-displays.trycloudflare.com/swagger/index.html',
        'ENABLE_API_LOGGING': 'true',
      });

      expect(config.apiProfile, isNot(ApiProfile.localEmulator));
      expect(config.apiBaseUrl.host, isNot('10.0.2.2'));
      expect(config.apiBaseUrl.host, isNot('localhost'));
    });
  });
}
