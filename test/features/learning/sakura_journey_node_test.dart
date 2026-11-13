import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_learning_journey_map.dart';

void main() {
  for (final percent in <int>[0, 25, 50, 60, 75, 100]) {
    testWidgets(
      'journey node renders $percent% progress without inferring a lock',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SakuraJourneyNodeButton(
                  lesson: StandardRoadmapLesson(
                    lessonId: 501,
                    title: 'Bài kiểm thử',
                    sortOrder: 1,
                    progressPercent: percent,
                    isCompleted: percent == 100,
                  ),
                  isCurrent: percent == 25,
                  diameter: 48,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );

        final ring = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(ring.value, percent / 100);
        await tester.tap(find.byKey(const ValueKey('standard_lesson_501')));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('current journey label shows the actual progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SakuraLearningJourneyMap(
              lessons: const [
                StandardRoadmapLesson(
                  lessonId: 501,
                  title: 'Bài kiểm thử',
                  sortOrder: 1,
                  progressPercent: 25,
                  isCompleted: false,
                ),
              ],
              currentStudyLevelName: 'N5',
              onOpenLesson: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Đang học • 25%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress ring animates from 50% to 75% without restarting', (
    tester,
  ) async {
    Widget node(int progress) => MaterialApp(
      home: Scaffold(
        body: SakuraJourneyNodeButton(
          lesson: StandardRoadmapLesson(
            lessonId: 501,
            title: 'Bài kiểm thử',
            sortOrder: 1,
            progressPercent: progress,
            isCompleted: false,
          ),
          isCurrent: true,
          diameter: 48,
          onTap: () {},
        ),
      ),
    );

    await tester.pumpWidget(node(50));
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.5,
    );
    await tester.pumpWidget(node(75));
    await tester.pump(const Duration(milliseconds: 210));
    final halfway = tester
        .widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        )
        .value!;
    expect(halfway, greaterThan(0.5));
    expect(halfway, lessThan(0.75));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.75,
    );
  });

  testWidgets('completed journey has no false next-lesson highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SakuraLearningJourneyMap(
              lessons: const [
                StandardRoadmapLesson(
                  lessonId: 501,
                  title: 'Bài kiểm thử',
                  sortOrder: 1,
                  progressPercent: 100,
                  isCompleted: true,
                ),
              ],
              currentStudyLevelName: 'N5',
              onOpenLesson: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bài tiếp theo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long journey reveals nearby lessons in bounded regions', (
    tester,
  ) async {
    final lessons = [
      for (var i = 0; i < 24; i++)
        StandardRoadmapLesson(
          lessonId: 501 + i,
          title: 'Bài ${i + 1}',
          sortOrder: i,
          progressPercent: i < 12 ? 100 : 0,
          isCompleted: i < 12,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SakuraLearningJourneyMap(
              lessons: lessons,
              currentStudyLevelName: 'N5',
              onOpenLesson: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('standard_lesson_513')), findsOneWidget);
    expect(find.byKey(const ValueKey('standard_lesson_501')), findsNothing);
    expect(find.byKey(const ValueKey('standard_lesson_524')), findsNothing);
    expect(find.byKey(const ValueKey('journey_show_earlier')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_show_more')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_show_earlier')));
    await tester.pump();
    expect(find.byKey(const ValueKey('standard_lesson_503')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
