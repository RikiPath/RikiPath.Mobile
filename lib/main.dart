import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/app.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/firebase_options.dart';

Object? firebaseInitializationError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appConfig = AppConfig.fromEnvironment();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[Firebase] Initialized successfully: project=${DefaultFirebaseOptions.currentPlatform.projectId}');
    }
  } catch (e, st) {
    firebaseInitializationError = e;
    debugPrint('[Firebase] Initialization error: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(appConfig)],
      child: const RikiPathApp(),
    ),
  );
}
