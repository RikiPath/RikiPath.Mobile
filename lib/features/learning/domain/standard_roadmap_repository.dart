import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';

abstract interface class StandardRoadmapRepository {
  Future<StandardRoadmap> load();
}
