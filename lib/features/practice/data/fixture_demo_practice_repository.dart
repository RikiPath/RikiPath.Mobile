import 'dart:async';

import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice_repository.dart';

class FixtureDemoPracticeRepository implements DemoPracticeRepository {
  const FixtureDemoPracticeRepository();

  @override
  Future<List<DemoReviewCard>> loadReviewQueue() {
    return Future<List<DemoReviewCard>>.value(_reviewQueue);
  }

  @override
  Future<DemoMockTest> loadMockTest() {
    return Future<DemoMockTest>.value(_mockTest);
  }

  @override
  Future<DemoAiGradingResult> gradeSubmission(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (text.trim().isEmpty) {
      return const DemoAiGradingResult(
        score: 0,
        feedback: 'Hãy nhập câu trả lời trước khi gửi chấm thử.',
      );
    }
    return const DemoAiGradingResult(
      score: 82,
      feedback:
          'Bài viết rõ ý, dùng đúng mẫu câu chính. Nên bổ sung thêm liên từ để câu tự nhiên hơn.',
    );
  }

  @override
  Future<List<DemoMentorPlan>> loadMentorPlans() {
    return Future<List<DemoMentorPlan>>.value(_plans);
  }

  @override
  Future<List<DemoMentorSlot>> loadMentorSlots() {
    return Future<List<DemoMentorSlot>>.value(_slots);
  }

  static const List<DemoReviewCard> _reviewQueue = [
    DemoReviewCard(
      id: 'fixture-review-vocab-asa',
      term: '朝',
      reading: 'あさ',
      meaning: 'buổi sáng',
      contentType: 'Vocabulary',
    ),
    DemoReviewCard(
      id: 'fixture-review-kanji-manabu',
      term: '学',
      reading: 'ガク / まなぶ',
      meaning: 'học tập',
      contentType: 'Kanji',
    ),
    DemoReviewCard(
      id: 'fixture-review-grammar-tari',
      term: '〜たり〜たりする',
      reading: null,
      meaning: 'liệt kê các hành động tiêu biểu',
      contentType: 'Grammar',
    ),
  ];

  static const DemoMockTest _mockTest = DemoMockTest(
    id: 'fixture-mock-n4-01',
    title: 'Đề thi thử N4 #01',
    level: 'N4',
    timeLimitMinutes: 25,
    questions: [
      DemoMockQuestion(
        id: 'fixture-q-1',
        section: 'Từ vựng / Kanji',
        prompt: '「朝」の読み方はどれですか。',
        options: [
          DemoMockOption(id: 'a', label: 'よる'),
          DemoMockOption(id: 'b', label: 'あさ'),
          DemoMockOption(id: 'c', label: 'ひる'),
          DemoMockOption(id: 'd', label: 'ばん'),
        ],
        correctOptionId: 'b',
        explanation: '朝 được đọc là あさ, nghĩa là buổi sáng.',
      ),
      DemoMockQuestion(
        id: 'fixture-q-2',
        section: 'Ngữ pháp',
        prompt: '「きのう、本を読んだり、音楽を聞いたりしました。」 nghĩa là gì?',
        options: [
          DemoMockOption(id: 'a', label: 'Hôm qua tôi chỉ đọc sách.'),
          DemoMockOption(id: 'b', label: 'Hôm qua tôi học ở trường.'),
          DemoMockOption(
            id: 'c',
            label:
                'Hôm qua tôi đọc sách, nghe nhạc và làm những việc tương tự.',
          ),
          DemoMockOption(id: 'd', label: 'Ngày mai tôi sẽ nghe nhạc.'),
        ],
        correctOptionId: 'c',
        explanation: '〜たり〜たりします dùng để liệt kê những hành động tiêu biểu.',
      ),
    ],
  );

  static const List<DemoMentorPlan> _plans = [
    DemoMentorPlan(
      id: 'fixture-plan-focused',
      name: 'Gói sửa lộ trình 1:1',
      description: 'Một buổi 30 phút cùng Mentor để rà soát mục tiêu JLPT.',
      priceLabel: 'Demo checkout',
    ),
  ];

  static const List<DemoMentorSlot> _slots = [
    DemoMentorSlot(
      id: 'fixture-slot-sat',
      mentorName: 'Nguyễn Sensei',
      timeLabel: 'Thứ 7, 09:30',
    ),
  ];
}
