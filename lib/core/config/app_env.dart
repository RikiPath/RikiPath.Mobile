enum AppEnv {
  development,
  staging,
  production;

  static AppEnv parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' => AppEnv.development,
      'staging' => AppEnv.staging,
      'production' => AppEnv.production,
      _ => throw const FormatException(
          'APP_ENV must be development, staging, or production.',
        ),
    };
  }

  bool get isProduction => this == AppEnv.production;
}
