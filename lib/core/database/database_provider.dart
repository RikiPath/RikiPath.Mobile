import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
