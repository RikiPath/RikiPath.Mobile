import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_compensation_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/learner_mentor_dtos.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_compensation_dtos.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_compensation.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_bank_account_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_compensation_screen.dart';

void main() {
  group('Mentor Compensation Domain JLPT Level Rules', () {
    test('normalizes JLPT levels consistently', () {
      expect(normalizeConsultationJlptLevel('n3'), 'N3');
      expect(normalizeConsultationJlptLevel(' N2 '), 'N2');
      expect(normalizeConsultationJlptLevel(null), '');
      expect(normalizeConsultationJlptLevel(''), '');
    });

    test('accepts N5-N2 and strictly rejects N1', () {
      expect(isSupportedConsultationJlptLevel('N5'), isTrue);
      expect(isSupportedConsultationJlptLevel('N4'), isTrue);
      expect(isSupportedConsultationJlptLevel('N3'), isTrue);
      expect(isSupportedConsultationJlptLevel('N2'), isTrue);
      expect(isSupportedConsultationJlptLevel('N1'), isFalse);
      expect(isSupportedConsultationJlptLevel('n1'), isFalse);
      expect(isSupportedConsultationJlptLevel('N0'), isFalse);
      expect(isSupportedConsultationJlptLevel(null), isFalse);
    });

    test('validates booking JLPT eligibility with strict guards', () {
      // N1 rejected
      final n1Error = validateBookingJlptEligibility(
        selectedJlptLevel: 'N1',
        mentorQualifiedLevels: ['N2', 'N3'],
        availableTicketsForLevel: 2,
        requireTicketNow: true,
      );
      expect(n1Error, contains('không hỗ trợ N1'));

      // Mentor not qualified
      final unqualError = validateBookingJlptEligibility(
        selectedJlptLevel: 'N2',
        mentorQualifiedLevels: ['N3', 'N4'],
        availableTicketsForLevel: 2,
        requireTicketNow: true,
      );
      expect(unqualError, contains('Cố vấn chưa được cấp quyền'));

      // Insufficient tickets for level
      final ticketError = validateBookingJlptEligibility(
        selectedJlptLevel: 'N3',
        mentorQualifiedLevels: ['N3'],
        availableTicketsForLevel: 0,
        requireTicketNow: true,
      );
      expect(ticketError, contains('Bạn chưa có vé tư vấn khả dụng'));

      // Valid booking passes
      final validResult = validateBookingJlptEligibility(
        selectedJlptLevel: 'N3',
        mentorQualifiedLevels: ['N3', 'N2'],
        availableTicketsForLevel: 1,
        requireTicketNow: true,
      );
      expect(validResult, isNull);
    });
  });

  group('Mentor Bank Account Input Validation', () {
    test('validates bank bin and account number format', () {
      expect(
        validateMentorBankAccountInput(
          bankBin: '970436',
          bankShortName: 'VCB',
          accountNumber: '1234567890',
          accountHolderName: 'NGUYEN VAN A',
        ),
        isNull,
      );

      // Missing BIN
      expect(
        validateMentorBankAccountInput(
          bankBin: '',
          bankShortName: 'VCB',
          accountNumber: '1234567890',
          accountHolderName: 'NGUYEN VAN A',
        ),
        contains('Mã BIN'),
      );

      // Missing bank short name
      expect(
        validateMentorBankAccountInput(
          bankBin: '970436',
          bankShortName: '',
          accountNumber: '1234567890',
          accountHolderName: 'NGUYEN VAN A',
        ),
        contains('tên ngân hàng'),
      );

      // Invalid account number (letters)
      expect(
        validateMentorBankAccountInput(
          bankBin: '970436',
          bankShortName: 'VCB',
          accountNumber: '1234ABC567',
          accountHolderName: 'NGUYEN VAN A',
        ),
        contains('chỉ gồm 6–20 chữ số'),
      );

      // Too short account number
      expect(
        validateMentorBankAccountInput(
          bankBin: '970436',
          bankShortName: 'VCB',
          accountNumber: '123',
          accountHolderName: 'NGUYEN VAN A',
        ),
        contains('chỉ gồm 6–20 chữ số'),
      );
    });
  });

  group('Mentor Compensation DTOs & Safety Guards', () {
    test('parses compensation overview safely with numbers and dates', () {
      final json = <String, Object?>{
        'mentorUserId': 101,
        'currentHourlyRate': {
          'id': 1,
          'mentorUserId': 101,
          'hourlyRateVnd': 350000.0,
          'currency': 'VND',
          'effectiveFromUtc': '2026-11-01T00:00:00Z',
          'isActive': true,
        },
        'activeQualifications': [
          {
            'id': 10,
            'mentorUserId': 101,
            'jlptLevel': 'N2',
            'isActive': true,
            'approvedAtUtc': '2026-10-01T00:00:00Z',
          },
          {
            'id': 11,
            'mentorUserId': 101,
            'jlptLevel': 'N3',
            'isActive': true,
          },
        ],
        'currentBankAccount': {
          'id': 50,
          'mentorUserId': 101,
          'bankBin': '970436',
          'bankShortName': 'Vietcombank',
          'maskedAccountNumber': '****5678',
          'accountHolderName': 'NGUYEN VAN A',
          'verificationStatus': 'Verified',
          'accountVersion': 1,
          'isCurrent': true,
        },
        'totalEligibleUnassignedVnd': 700000,
        'totalLockedInPayrollVnd': 0,
        'totalPaidVnd': 2500000,
        'recentEarnings': [],
        'recentPayrolls': [],
        'recentPayouts': [],
      };

      final domain = parseMentorCompensationOverview(json);

      expect(domain.mentorUserId, 101);
      expect(domain.currentHourlyRate?.hourlyRateVnd, 350000.0);
      expect(domain.activeQualifications.length, 2);
      expect(domain.activeQualifications.first.jlptLevel, 'N2');
      expect(domain.currentBankAccount?.maskedAccountNumber, '****5678');
      expect(domain.totalEligibleUnassignedVnd, 700000);
      expect(domain.totalPaidVnd, 2500000);
    });

    test('payout status safety: Processing and Unknown are NOT Paid', () {
      final processing = parseMentorPayoutObligation({
        'id': 99,
        'mentorPayrollPeriodId': 5,
        'mentorUserId': 101,
        'payableAmountVnd': 1050000,
        'paidAmountVnd': 0,
        'currency': 'VND',
        'selectedExecutionMethod': 'PayOsPayout',
        'status': 'Processing',
      });
      expect(processing.isPaid, isFalse);
      expect(processing.status, 'Processing');
      expect(payoutStatusLabel(processing.status), 'Đang xử lý chuyển tiền');

      final unknown = parseMentorPayoutObligation({
        'id': 100,
        'mentorPayrollPeriodId': 5,
        'mentorUserId': 101,
        'payableAmountVnd': 1050000,
        'paidAmountVnd': 0,
        'currency': 'VND',
        'selectedExecutionMethod': 'PayOsPayout',
        'status': 'UnknownPendingReconciliation',
      });
      expect(unknown.isPaid, isFalse);
      expect(payoutStatusLabel(unknown.status), contains('đối soát'));

      final paid = parseMentorPayoutObligation({
        'id': 101,
        'mentorPayrollPeriodId': 5,
        'mentorUserId': 101,
        'payableAmountVnd': 1050000,
        'paidAmountVnd': 1050000,
        'currency': 'VND',
        'selectedExecutionMethod': 'ManualBankTransfer',
        'status': 'Paid',
      });
      expect(paid.isPaid, isTrue);
      expect(payoutStatusLabel(paid.status), 'Đã chi trả');
    });

    test('earning entry parses JLPT coefficient and frozen snapshot safely', () {
      final json = <String, Object?>{
        'id': 200,
        'mentorUserId': 101,
        'mentorBookingId': 501,
        'jlptLevel': 'N2',
        'frozenHourlyRateVnd': 300000,
        'frozenLevelCoefficient': 1.25,
        'scheduledMinutes': 90,
        'approvedEligibleMinutes': 90,
        'scheduledAmountVnd': 562500,
        'eligibleAmountVnd': 562500,
        'currency': 'VND',
        'status': 'Eligible',
        'earnedAtUtc': '2026-11-04T10:00:00Z',
      };

      final domain = parseMentorEarningEntry(json);

      expect(domain.jlptLevel, 'N2');
      expect(domain.frozenHourlyRateVnd, 300000);
      expect(domain.frozenLevelCoefficient, 1.25);
      expect(domain.scheduledMinutes, 90);
      expect(domain.eligibleAmountVnd, 562500);
      expect(earningStatusLabel(domain.status), 'Đủ điều kiện, chờ chốt kỳ');
    });
  });

  group('Learner JLPT Level-Bound Integration', () {
    test('LearnerCreditBalance parses activeGrants and filters by level', () {
      final json = <String, Object?>{
        'totalAvailableCredits': 3,
        'activeGrants': [
          {
            'grantId': 1001,
            'userSubscriptionId': 50,
            'certificateLevelId': 3,
            'jlptLevel': 'N3',
            'availableQuantity': 2,
          },
          {
            'grantId': 1002,
            'userSubscriptionId': 51,
            'certificateLevelId': 2,
            'jlptLevel': 'N2',
            'availableQuantity': 1,
          },
        ],
      };

      final dto = LearnerCreditBalanceDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.availableBalance, 3);
      expect(domain.activeGrants.length, 2);
      expect(domain.availableForLevel('N3'), 2);
      expect(domain.availableForLevel('N2'), 1);
      expect(domain.availableForLevel('N4'), 0);
      expect(domain.availableForLevel('N5'), 0);
    });

    test('PurchaseMentorPlanRequestDto serializes jlptLevel in uppercase', () {
      const dto = PurchaseMentorPlanRequestDto(
        subscriptionPlanId: 10,
        mentorAvailabilityId: 200,
        jlptLevel: 'n3',
      );
      final map = dto.toJson();
      expect(map['subscriptionPlanId'], 10);
      expect(map['jlptLevel'], 'N3');
    });

    test('BookWithCreditRequestDto serializes jlptLevel in uppercase', () {
      const dto = BookWithCreditRequestDto(
        mentorAvailabilityId: 200,
        operationKey: 'op_123',
        notes: 'Học ngữ pháp',
        jlptLevel: 'n2',
      );
      final map = dto.toJson();
      expect(map['mentorAvailabilityId'], 200);
      expect(map['operationKey'], 'op_123');
      expect(map['notes'], 'Học ngữ pháp');
      expect(map['jlptLevel'], 'N2');
    });

    test('MentorMeetingPlanDto maps jlptLevel and certificateLevelId', () {
      final json = <String, Object?>{
        'id': 15,
        'name': 'Gói trải nghiệm N3',
        'durationDays': 30,
        'price': 450000,
        'meetingSessionCount': 1,
        'jlptLevel': 'N3',
        'certificateLevelId': 3,
        'features': [
          {'id': 1, 'name': '1 buổi tư vấn 90 phút'},
        ],
      };

      final dto = MentorMeetingPlanDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.jlptLevel, 'N3');
      expect(domain.certificateLevelId, 3);
      expect(domain.name, 'Gói trải nghiệm N3');
      expect(domain.meetingSessionCount, 1);
    });

    test('BookableMentorDto reads teachingJlptLevels', () {
      final json = <String, Object?>{
        'id': 42,
        'name': 'Thầy Tanaka',
        'teachingJlptLevels': ['N3', 'N2'],
      };

      final dto = BookableMentorDto.fromJson(json);
      final domain = dto.toDomain();

      expect(domain.name, 'Thầy Tanaka');
      expect(domain.teachingJlptLevels, ['N3', 'N2']);
    });
  });

  group('Mentor Compensation Presentation Widget Tests', () {
    testWidgets('MentorCompensationScreen renders 4 navigation tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MentorCompensationScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Buổi tư vấn'), findsOneWidget);
      expect(find.text('Kỳ lương'), findsOneWidget);
      expect(find.text('Lịch sử chi trả'), findsOneWidget);
    });

    testWidgets('MentorBankAccountScreen renders form and inputs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MentorBankAccountScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tài khoản nhận thù lao'), findsOneWidget);
      expect(find.byKey(const Key('mentor_bank_bin_field')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bank_name_field')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bank_account_field')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bank_holder_field')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bank_submit_button')), findsOneWidget);
    });
  });
}
