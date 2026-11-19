import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_audio_player.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_content_view.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/data/api_mock_test_repository.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/widgets/mock_test_review_sheets.dart';
import 'package:rikipath_mobile/features/speech/data/speech_api_paths.dart';
import 'package:rikipath_mobile/features/speech/data/speech_audio_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/data/japanese_dictionary_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_writing_practice_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/data/learner_essay_draft_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/data/writing_api_paths.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Lesson Notes & Audio Player', () {
    testWidgets(
      'LessonNotesContent displays importantNotes and persists personal note locally',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'lesson_personal_note_lesson-7': 'Ghi chú đã lưu trước đó',
        });
        final lesson = Lesson(
          routeId: 'lesson-7',
          remoteLessonId: 7,
          title: 'Bài 7: Trợ từ',
          focus: 'Grammar',
          level: JlptLevel.n5,
          category: 'Grammar',
          curriculum: 'JLPT N5',
          chapterNumber: 1,
          lessonNumber: 7,
          durationSeconds: 300,
          objective: 'Phân biệt は và が',
          parts: const [],
          vocabulary: const [],
          kanji: const [],
          detailVocabularyCount: 0,
          videoVocabularyCount: 0,
          relatedGrammar: const [],
          article: const LessonArticle(
            formulas: <String>[],
            meaning: '',
            usageSteps: <String>[],
            examples: <LessonExample>[],
            importantNotes: <String>['Trợ từ は đánh dấu chủ đề câu.'],
          ),
          progress: const LessonProgress(
            progressPercent: 0,
            resumePositionSeconds: 0,
            isCompleted: false,
          ),
          availability: LessonAvailability.available,
          noteCount: 1,
          streakDays: 0,
          detailXp: 0,
          completionXp: 0,
          masteryItems: const [],
          mediaSource: const LessonMediaSource.none(),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: LessonNotesContent(lesson: lesson),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Trợ từ は đánh dấu chủ đề câu.'),
          findsOneWidget,
        );
        expect(find.text('Ghi chú đã lưu trước đó'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('lesson_personal_note_field')),
          'Cần ôn lại thêm ví dụ với が',
        );
        await tester.tap(find.byKey(const Key('lesson_personal_note_save')));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('lesson_personal_note_lesson-7'),
          'Cần ôn lại thêm ví dụ với が',
        );
        expect(find.text('Đã lưu ghi chú cho bài học này.'), findsOneWidget);
      },
    );

    testWidgets(
      'RikiNetworkAudioPlayer shows validation error for invalid URL safely',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: RikiNetworkAudioPlayer(audioUrl: 'not-a-valid-url'),
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.play_circle_filled_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Đường dẫn âm thanh không hợp lệ.'), findsOneWidget);
      },
    );
  });

  group('MockTest History & Wrong Questions Review Sheets', () {
    testWidgets(
      'MockTest wrong-questions sheet renders question and Quizlet reveal',
      (tester) async {
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/MockTest/wrong-questions') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'questionId': 88,
                          'questionText': 'Chọn cách đọc đúng của 「日本」',
                          'questionType': 'SingleChoice',
                          'selectedOptionId': 2,
                          'timesAnsweredWrong': 3,
                          'explanation': 'Cách đọc chuẩn là にほん.',
                          'options': [
                            <String, Object?>{
                              'optionId': 1,
                              'optionText': 'にほん',
                              'isCorrect': true,
                            },
                            <String, Object?>{
                              'optionId': 2,
                              'optionText': 'ひもと',
                              'isCorrect': false,
                            },
                          ],
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mockTestRepositoryProvider.overrideWithValue(
                ApiMockTestRepository(ApiClient(dio, const ApiErrorMapper())),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('vi'),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => FilledButton(
                    onPressed: () =>
                        showMockTestWrongQuestionsSheet(context, ref),
                    child: const Text('Open Wrong'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Wrong'));
        await tester.pumpAndSettle();

        expect(find.text('Sai 3 lần'), findsOneWidget);
        expect(find.textContaining('Chọn cách đọc đúng của'), findsOneWidget);
        await tester.tap(find.text('Hiện đáp án & giải thích'));
        await tester.pumpAndSettle();
        expect(find.text('Cách đọc chuẩn là にほん.'), findsOneWidget);
      },
    );
  });

  group('Batch 6.3 API Contracts', () {
    test('JapaneseDictionaryRepository calls kana search endpoint', () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: <String, Object?>{
                  'isSuccess': true,
                  'result': [
                    <String, Object?>{
                      'id': 5,
                      'surface': '食べる',
                      'readingKana': 'たべる',
                      'meaning': 'ăn',
                      'sinoVietnamese': 'THỰC',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final res = await JapaneseDictionaryRepository(
        ApiClient(dio, const ApiErrorMapper()),
      ).searchByKana('たべる');
      expect(captured.path, '/api/japanese-dictionary/search');
      expect(captured.queryParameters['readingKana'], 'たべる');
      expect(res.single.surface, '食べる');
      expect(res.single.sinoVietnamese, 'THỰC');
    });

    test(
      'Writing kanaAll, kanjiRecognize, LearnerEssay drafts & Speech REST contracts',
      () async {
        final paths = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              paths.add('${options.method} ${options.path}');
              if (options.path == WritingApiPaths.kanaAll) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': [
                        <String, Object?>{
                          'kanaCharacterId': 1,
                          'character': 'あ',
                          'type': 'Hiragana',
                          'romaji': 'a',
                          'strokeCount': 3,
                          'isNew': true,
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              if (options.path == WritingApiPaths.kanjiRecognize) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': ['山', '出'],
                    },
                  ),
                );
                return;
              }
              if (options.path == '/api/learner-essays' &&
                  options.method == 'POST') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'id': 14,
                        'title': 'Essay #14',
                        'contentText': 'さくらがきれいです。',
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/api/learner-essays/14/rescan') {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{'text': 'さくらがきれい'},
                    },
                  ),
                );
                return;
              }
              if (options.path == SpeechApiPaths.transcribe) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{'text': 'おはようございます'},
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final client = ApiClient(dio, const ApiErrorMapper());
        final writingRepo = ApiWritingPracticeRepository(client);
        final kanaItems = await writingRepo.loadQueue(
          const WritingQueueRequest(
            script: WritingScript.hiragana,
            kanjiCollection: KanjiWritingCollection.all,
          ),
        );
        expect(kanaItems.single.character, 'あ');

        final candidates = await writingRepo.recognizeKanjiPng(
          Uint8List.fromList([137, 80, 78, 71]),
        );
        expect(candidates, ['山', '出']);

        final draftRepo = LearnerEssayDraftRepository(client);
        final created = await draftRepo.createDraft(contentText: 'さくらがきれいです。');
        expect(created.id, 14);
        final rescanned = await draftRepo.rescanDraft(
          14,
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'page.png',
          contentType: 'image/png',
        );
        expect(rescanned, 'さくらがきれい');

        final speechRepo = SpeechAudioRepository(client);
        final transcript = await speechRepo.transcribeAudio(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'voice.m4a',
        );
        expect(transcript, 'おはようございます');
        expect(paths, contains('GET /api/kana-writing-practice/all'));
        expect(paths, contains('POST /api/KanjiWritingPractice/recognize'));
        expect(paths, contains('POST /api/learner-essays'));
        expect(paths, contains('POST /api/learner-essays/14/rescan'));
        expect(paths, contains('POST /api/Speech/transcribe'));
      },
    );
  });
}
