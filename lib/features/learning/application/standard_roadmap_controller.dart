import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/data/api_standard_roadmap_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap_repository.dart';

final standardRoadmapRepositoryProvider = Provider<StandardRoadmapRepository>(
  (ref) => ApiStandardRoadmapRepository(ref.watch(apiClientProvider)),
);

final standardRoadmapProvider = FutureProvider.autoDispose<StandardRoadmap>(
  (ref) => ref.watch(standardRoadmapRepositoryProvider).load(),
);
