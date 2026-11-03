import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_learner_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ApiClient _createTestClient(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000',
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.httpClientAdapter = _FakeHttpAdapter(handler);
  return ApiClient(dio, const ApiErrorMapper());
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('Stage 12 Mobile Integration - V3 Contracts & DTOs', () {
    test(
      'BookableMentorDto parses Stage 07 PublicMentorCardResponse correctly',
      () {
        final backendJson = <String, Object?>{
          'mentorId': 42,
          'name': 'Sensei Kenji',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'bio': 'Chuyên gia luyện thi JLPT N1/N2 tại Tokyo',
          'expertise': 'Luyện thi N1, Hội thoại thương mại',
          'jlptLevel': 'N1',
          'yearsOfExperience': 8,
          'workplace': 'Tokyo University',
          'isBookable': true,
        };

        final dto = BookableMentorDto.fromJson(backendJson);
        final domain = dto.toDomain();

        expect(domain.id, 42);
        expect(domain.name, 'Sensei Kenji');
        expect(domain.avatarUrl, 'https://example.com/avatar.jpg');
        expect(domain.bio, 'Chuyên gia luyện thi JLPT N1/N2 tại Tokyo');
        expect(domain.headline, 'Luyện thi N1, Hội thoại thương mại');
        expect(domain.jlptLevels, ['N1']);
        expect(domain.teachingMethod, 'Tokyo University');
      },
    );

    test(
      'readLearnerMentorResultList unwraps PagedResult from SearchMentors',
      () {
        final pagedEnvelope = <String, Object?>{
          'isSuccess': true,
          'statusCode': 200,
          'result': {
            'items': [
              {
                'mentorId': 101,
                'name': 'Sensei Sakura',
                'avatarUrl': null,
                'expertise': 'Kaiwa N3',
                'jlptLevel': 'N2',
              },
              {
                'mentorId': 102,
                'name': 'Sensei Takeshi',
                'avatarUrl': null,
                'expertise': 'Ngữ pháp N1',
                'jlptLevel': 'N1',
              },
            ],
            'totalCount': 2,
            'pageNumber': 1,
            'pageSize': 10,
          },
        };

        final items = readLearnerMentorResultList(pagedEnvelope);
        expect(items.length, 2);
        expect(items[0]['mentorId'], 101);
        expect(items[1]['name'], 'Sensei Takeshi');
      },
    );

    test('LearnerCreditBalanceDto maps Stage 06 credit balance response', () {
      final json = <String, Object?>{
        'balance': 5,
        'availableBalance': 4,
        'pendingHoldCount': 1,
        'expiresAtUtc': '2026-12-31T23:59:59Z',
      };

      final dto = LearnerCreditBalanceDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.balance, 5);
      expect(domain.availableBalance, 4);
      expect(domain.pendingHoldCount, 1);
      expect(domain.hasCredits, isTrue);
      expect(domain.expiresAtUtc, DateTime.utc(2026, 12, 31, 23, 59, 59));
    });

    test('CancellationEligibilityDto maps Stage 10 policy tiers', () {
      final earlyJson = <String, Object?>{
        'isEligible': true,
        'tier': 'Early_FullRefund',
        'expectedRefundPercent': 100,
        'refundAmountCredits': 1,
        'canReschedule': true,
        'cutoffHours': 24,
        'message': 'Được hoàn 100% tín dụng khi hủy trước 24h',
      };

      final dto = CancellationEligibilityDto.fromJson(earlyJson);
      final domain = dto.toDomain();

      expect(domain.isEligible, isTrue);
      expect(domain.isFullRefund, isTrue);
      expect(domain.tier, 'Early_FullRefund');
      expect(domain.expectedRefundPercent, 100);
      expect(domain.canReschedule, isTrue);
    });

    test(
      'CancellationEligibilityDto enforces Revised Ticket Policy (integer 1 or 0 tickets)',
      () {
        // Backend response >= 24h: 1 Ticket refund
        final earlyBackendJson = <String, Object?>{
          'bookingId': 100,
          'canCancel': true,
          'canReschedule': true,
          'eligibleForFullRefund': true,
          'hoursUntilStart': 26.5,
          'tier': 'Early_FullRefund',
          'message': 'Đủ điều kiện hủy được hoàn 1 Ticket (từ 24 giờ trở lên).',
        };
        final earlyDto = CancellationEligibilityDto.fromJson(
          earlyBackendJson,
        ).toDomain();
        expect(earlyDto.isEligible, isTrue);
        expect(earlyDto.isFullRefund, isTrue);
        expect(earlyDto.refundAmountCredits, 1);
        expect(earlyDto.expectedRefundPercent, 100);
        expect(earlyDto.canReschedule, isTrue);
        expect(earlyDto.cutoffHours, 24);

        // Backend response < 24h: strictly 0 Ticket refund (no 0.5 ticket, no 50%)
        final lateBackendJson = <String, Object?>{
          'bookingId': 101,
          'canCancel': true,
          'canReschedule': false,
          'eligibleForFullRefund': false,
          'hoursUntilStart': 12.0,
          'tier': 'Late_NoRefund',
          'message': 'Hủy muộn (dưới 24 giờ): không được tự động hoàn Ticket.',
        };
        final lateDto = CancellationEligibilityDto.fromJson(
          lateBackendJson,
        ).toDomain();
        expect(lateDto.isEligible, isTrue);
        expect(lateDto.isFullRefund, isFalse);
        expect(lateDto.refundAmountCredits, 0);
        expect(lateDto.expectedRefundPercent, 0);
        expect(lateDto.canReschedule, isFalse);
        expect(lateDto.cutoffHours, 24);

        // Backend response when session already started: cannot cancel, 0 ticket refund
        final startedJson = <String, Object?>{
          'bookingId': 102,
          'canCancel': false,
          'canReschedule': false,
          'eligibleForFullRefund': false,
          'hoursUntilStart': -1.0,
          'tier': 'SessionStarted',
          'message': 'Buổi tư vấn đã bắt đầu hoặc kết thúc, không thể hủy.',
        };
        final startedDto = CancellationEligibilityDto.fromJson(
          startedJson,
        ).toDomain();
        expect(startedDto.isEligible, isFalse);
        expect(startedDto.isFullRefund, isFalse);
        expect(startedDto.refundAmountCredits, 0);
        expect(startedDto.expectedRefundPercent, 0);
        expect(startedDto.canReschedule, isFalse);
      },
    );

    test('MentorRatingSummaryDto maps Stage 11 rating breakdown', () {
      final summaryJson = <String, Object?>{
        'mentorId': 88,
        'averageRating': 4.75,
        'totalReviews': 20,
        'starCounts': {'5': 15, '4': 5},
        'positiveRatePercentage': 100.0,
      };

      final dto = MentorRatingSummaryDto.fromJson(summaryJson);
      final domain = dto.toDomain();

      expect(domain.mentorId, 88);
      expect(domain.averageRating, 4.75);
      expect(domain.totalReviews, 20);
      expect(domain.starCounts[5], 15);
      expect(domain.starCounts[4], 5);
      expect(domain.positiveRatePercentage, 100.0);
    });

    test('LearnerDisputeDto maps Stage 11 dispute lifecycle and evidence', () {
      final disputeJson = <String, Object?>{
        'id': 7,
        'mentorBookingId': 123,
        'category': 1, // MentorAbsent
        'status': 2, // UnderReview
        'description': 'Mentor không tham gia phòng học đúng giờ',
        'resolutionNote': null,
        'refundApproved': null,
        'createdAtUtc': '2026-10-31T10:00:00Z',
      };

      final dto = LearnerDisputeDto.fromJson(disputeJson);
      final domain = dto.toDomain();

      expect(domain.id, 7);
      expect(domain.bookingId, 123);
      expect(domain.category, 1);
      expect(domain.categoryLabel, 'Mentor vắng mặt');
      expect(domain.status, 2);
      expect(domain.statusLabel, 'Đang xem xét');
    });
  });

  group(
    'Stage 12 Mobile Integration - ApiLearnerMentorRepository with real endpoints',
    () {
      test(
        'loadCreditBalance queries the canonical learner credits route',
        () async {
          String? requestedPath;
          final client = _createTestClient((options) async {
            requestedPath = options.path;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {
                'balance': 3,
                'availableBalance': 3,
                'pendingHoldCount': 0,
                'expiresAtUtc': null,
              },
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final balance = await repo.loadCreditBalance();

          expect(requestedPath, '/api/learner/credits/balance');
          expect(balance.balance, 3);
          expect(balance.availableBalance, 3);
          expect(balance.hasCredits, isTrue);
        },
      );

      test(
        'bookWithCredit posts to the canonical learner booking route with operationKey',
        () async {
          String? requestedPath;
          Map<String, dynamic>? postedData;

          final client = _createTestClient((options) async {
            requestedPath = options.path;
            postedData = options.data as Map<String, dynamic>?;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {
                'id': 501,
                'userSubscriptionId': 10,
                'mentorAvailabilityId': 77,
                'mentorId': 5,
                'mentorName': 'Sensei Yamada',
                'status': 'Accepted',
                'paymentStatus': 'Paid',
                'scheduledAt': '2026-11-05T09:00:00Z',
                'roomId': 'room-501-abc',
              },
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final booking = await repo.bookWithCredit(
            slotId: 77,
            operationKey: 'op-key-123',
            notes: 'Chuẩn bị ôn Dokkai N2',
          );

          expect(requestedPath, '/api/learner/mentor-bookings');
          expect(postedData?['mentorAvailabilityId'], 77);
          expect(postedData?['operationKey'], 'op-key-123');
          expect(postedData?['notes'], 'Chuẩn bị ôn Dokkai N2');
          expect(booking.id, 501);
          expect(booking.mentorName, 'Sensei Yamada');
        },
      );

      test(
        'checkCancellationEligibility queries the canonical cancellation route',
        () async {
          String? requestedPath;
          final client = _createTestClient((options) async {
            requestedPath = options.path;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {
                'isEligible': true,
                'tier': 'Early_FullRefund',
                'expectedRefundPercent': 100,
                'refundAmountCredits': 1,
                'canReschedule': true,
                'cutoffHours': 24,
              },
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final elig = await repo.checkCancellationEligibility(501);

          expect(
            requestedPath,
            '/api/mentor-bookings/501/cancellation-eligibility',
          );
          expect(elig.isEligible, isTrue);
          expect(elig.expectedRefundPercent, 100);
          expect(elig.canReschedule, isTrue);
        },
      );

      test(
        'cancelBooking posts to the canonical cancellation route',
        () async {
          String? requestedPath;
          Map<String, dynamic>? postedData;

          final client = _createTestClient((options) async {
            requestedPath = options.path;
            postedData = options.data as Map<String, dynamic>?;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {'bookingId': 501, 'status': 'Cancelled'},
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final ok = await repo.cancelBooking(
            bookingId: 501,
            reason: 'Bận việc đột xuất',
            requestException: true,
            exceptionReason: 'Đi công tác khẩn',
          );

          expect(ok, isTrue);
          expect(requestedPath, '/api/mentor-bookings/501/cancel');
          expect(postedData?['reason'], 'Bận việc đột xuất');
          expect(postedData?['requestException'], isTrue);
          expect(postedData?['exceptionReason'], 'Đi công tác khẩn');
        },
      );

      test(
        'rescheduleBooking posts to the canonical rescheduling route',
        () async {
          String? requestedPath;
          Map<String, dynamic>? postedData;

          final client = _createTestClient((options) async {
            requestedPath = options.path;
            postedData = options.data as Map<String, dynamic>?;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {'bookingId': 501, 'newSlotId': 88},
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final ok = await repo.rescheduleBooking(
            bookingId: 501,
            newSlotId: 88,
          );

          expect(ok, isTrue);
          expect(requestedPath, '/api/mentor-bookings/501/reschedule');
          expect(postedData?['newMentorAvailabilityId'], 88);
        },
      );

      test(
        'createReview posts to the canonical mentor reviews route with 1-5 rating',
        () async {
          String? requestedPath;
          Map<String, dynamic>? postedData;

          final client = _createTestClient((options) async {
            requestedPath = options.path;
            postedData = options.data as Map<String, dynamic>?;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {
                'id': 19,
                'mentorBookingId': 501,
                'learnerName': 'Nguyễn Văn A',
                'rating': 5,
                'comment': 'Sensei hướng dẫn rất tận tình và chi tiết!',
                'createdAtUtc': '2026-10-31T12:00:00Z',
              },
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final review = await repo.createReview(
            bookingId: 501,
            rating: 5,
            comment: 'Sensei hướng dẫn rất tận tình và chi tiết!',
          );

          expect(requestedPath, '/api/mentor-reviews');
          expect(postedData?['mentorBookingId'], 501);
          expect(postedData?['rating'], 5);
          expect(review.id, 19);
          expect(review.rating, 5);
          expect(review.comment, 'Sensei hướng dẫn rất tận tình và chi tiết!');
        },
      );

      test(
        'createDispute posts to the canonical mentor disputes route within 48h deadline',
        () async {
          String? requestedPath;
          Map<String, dynamic>? postedData;

          final client = _createTestClient((options) async {
            requestedPath = options.path;
            postedData = options.data as Map<String, dynamic>?;
            return _jsonResponse({
              'isSuccess': true,
              'statusCode': 200,
              'result': {
                'id': 8,
                'mentorBookingId': 501,
                'category': 3, // MediaRoomIssue
                'status': 1, // Submitted
                'description': 'Mất kết nối âm thanh trong suốt 30 phút đầu',
                'createdAtUtc': '2026-10-31T12:30:00Z',
              },
            });
          });

          final repo = ApiLearnerMentorRepository(client);
          final dispute = await repo.createDispute(
            bookingId: 501,
            category: 3,
            reason: 'Mất kết nối âm thanh trong suốt 30 phút đầu',
          );

          expect(requestedPath, '/api/mentor-disputes');
          expect(postedData?['mentorBookingId'], 501);
          expect(postedData?['category'], 3);
          expect(dispute.id, 8);
          expect(dispute.categoryLabel, 'Sự cố phòng họp trực tuyến');
          expect(dispute.statusLabel, 'Đã gửi khiếu nại');
        },
      );

    },
  );
}
