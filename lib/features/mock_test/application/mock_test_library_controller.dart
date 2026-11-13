import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';

class MockTestLevelGroup {
  const MockTestLevelGroup({required this.level, required this.tests});

  final JlptLevelCatalogItem level;
  final List<LiveMockTestSummary> tests;
}

/// Holds the currently selected JLPT level code (e.g. 'N5', 'N4') in the Mock Exam Hub.
/// Keeping it in Riverpod preserves the learner's tab selection when returning
/// from taking or reviewing a test.
class SelectedMockTestLevelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String code) => state = code;
}

final selectedMockTestLevelProvider =
    NotifierProvider.autoDispose<SelectedMockTestLevelNotifier, String?>(
      SelectedMockTestLevelNotifier.new,
    );

final mockTestLibraryProvider =
    FutureProvider.autoDispose<List<MockTestLevelGroup>>((ref) async {
      final allLevels = await ref.read(jlptCatalogRepositoryProvider).loadLevels();
      final levels = allLevels
          .where((level) => level.level != JlptLevel.n1)
          .toList(growable: false);
      final repository = ref.read(mockTestRepositoryProvider);
      final groups = await Future.wait(
        levels.map((level) async {
          try {
            final tests = await repository.loadTestsByLevel(level.id);
            return MockTestLevelGroup(level: level, tests: tests);
          } on NotFoundError {
            // The Backend returns 404 when a valid level has no published tests.
            return MockTestLevelGroup(level: level, tests: const []);
          }
        }),
      );
      return groups
          .where((group) => group.tests.isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => a.level.sortOrder.compareTo(b.level.sortOrder));
    });
