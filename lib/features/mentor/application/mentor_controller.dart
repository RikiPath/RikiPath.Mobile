import 'dart:typed_data';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';

final mentorRepositoryProvider = Provider<MentorRepository>(
  (ref) => ApiMentorRepository(ref.watch(apiClientProvider)),
);

final mentorAvailabilityControllerProvider =
    AsyncNotifierProvider<
      MentorAvailabilityController,
      List<MentorAvailabilitySlot>
    >(MentorAvailabilityController.new, retry: (_, _) => null);

final mentorMeetingsControllerProvider =
    AsyncNotifierProvider<MentorMeetingsController, List<MentorMeetingSummary>>(
      MentorMeetingsController.new,
      retry: (_, _) => null,
    );

final mentorProfileControllerProvider =
    AsyncNotifierProvider<MentorProfileController, MentorProfileData>(
      MentorProfileController.new,
      retry: (_, _) => null,
    );

final mentorWeeklyScheduleControllerProvider =
    NotifierProvider<MentorWeeklyScheduleController, MentorWeeklyScheduleState>(
      MentorWeeklyScheduleController.new,
    );

class MentorWeeklyScheduleState {
  const MentorWeeklyScheduleState({
    required this.selectedWeekMonday,
    required this.currentWeekMonday,
    required this.registeredPeriods,
    required this.publishedSlots,
    required this.isLoading,
    required this.isSaving,
    this.errorMessage,
    this.successMessage,
  });

  final DateTime selectedWeekMonday;
  final DateTime currentWeekMonday;
  final Set<WeeklyPeriodItem> registeredPeriods;
  final List<MentorAvailabilitySlot> publishedSlots;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  DateTime get nextWeekMonday => currentWeekMonday.add(const Duration(days: 7));

  bool get isNextWeek =>
      selectedWeekMonday.year == nextWeekMonday.year &&
      selectedWeekMonday.month == nextWeekMonday.month &&
      selectedWeekMonday.day == nextWeekMonday.day;

  bool get isCurrentWeek =>
      selectedWeekMonday.year == currentWeekMonday.year &&
      selectedWeekMonday.month == currentWeekMonday.month &&
      selectedWeekMonday.day == currentWeekMonday.day;

  static DateTime get vietnamNow =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  bool get isRegistrationOpen {
    return isRegistrationOpenAt(DateTime.now().toUtc());
  }

  bool isRegistrationOpenAt(DateTime nowUtc) {
    final vietnamWallTime = nowUtc.toUtc().add(const Duration(hours: 7));
    final fridayDeadline = DateTime.utc(
      currentWeekMonday.year,
      currentWeekMonday.month,
      currentWeekMonday.day + 4,
      18,
      0,
    );
    return isNextWeek && vietnamWallTime.isBefore(fridayDeadline);
  }

  bool get hasMinimumPeriods => registeredPeriods.length >= 3;

  MentorWeeklyScheduleState copyWith({
    DateTime? selectedWeekMonday,
    DateTime? currentWeekMonday,
    Set<WeeklyPeriodItem>? registeredPeriods,
    List<MentorAvailabilitySlot>? publishedSlots,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MentorWeeklyScheduleState(
      selectedWeekMonday: selectedWeekMonday ?? this.selectedWeekMonday,
      currentWeekMonday: currentWeekMonday ?? this.currentWeekMonday,
      registeredPeriods: registeredPeriods ?? this.registeredPeriods,
      publishedSlots: publishedSlots ?? this.publishedSlots,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class MentorWeeklyScheduleController
    extends Notifier<MentorWeeklyScheduleState> {
  static DateTime getMondayOf(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  MentorWeeklyScheduleState build() {
    final vnNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final curMonday = getMondayOf(vnNow);
    final nextMonday = curMonday.add(const Duration(days: 7));
    final fridayDeadline = DateTime.utc(
      curMonday.year,
      curMonday.month,
      curMonday.day + 4,
      18,
      0,
    );

    final initialMonday = vnNow.isBefore(fridayDeadline)
        ? nextMonday
        : curMonday;

    final initialState = MentorWeeklyScheduleState(
      selectedWeekMonday: initialMonday,
      currentWeekMonday: curMonday,
      registeredPeriods: const {},
      publishedSlots: const [],
      isLoading: true,
      isSaving: false,
    );

    Future.microtask(loadSchedule);

    return initialState;
  }

  Future<void> loadSchedule({bool clearMessages = true}) async {
    state = state.copyWith(isLoading: true, clearMessages: clearMessages);
    try {
      final repository = ref.read(mentorRepositoryProvider);
      final weeklyItems = await repository.loadWeeklySchedule(
        state.selectedWeekMonday,
      );
      final allSlots = await repository.loadAvailability();

      final weekStart = state.selectedWeekMonday;
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekPublishedSlots = allSlots.where((slot) {
        final slotStart = slot.startTime.displayValue;
        return slot.isApproved &&
            slotStart.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            slotStart.isBefore(weekEnd);
      }).toList();

      final periods = weeklyItems
          .map((item) => WeeklyPeriodItem(date: item.date, period: item.period))
          .toSet();

      state = state.copyWith(
        isLoading: false,
        registeredPeriods: periods,
        publishedSlots: weekPublishedSlots,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chưa thể tải lịch đăng ký tuần này. Vui lòng thử lại.',
      );
    }
  }

  void nextWeek() {
    state = state.copyWith(
      selectedWeekMonday: state.selectedWeekMonday.add(const Duration(days: 7)),
      clearMessages: true,
    );
    loadSchedule();
  }

  void previousWeek() {
    state = state.copyWith(
      selectedWeekMonday: state.selectedWeekMonday.subtract(
        const Duration(days: 7),
      ),
      clearMessages: true,
    );
    loadSchedule();
  }

  void togglePeriod(DateTime date, String period) {
    if (!state.isRegistrationOpen) return;
    final item = WeeklyPeriodItem(
      date: DateTime(date.year, date.month, date.day),
      period: period,
    );
    final updated = Set<WeeklyPeriodItem>.from(state.registeredPeriods);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
    }
    state = state.copyWith(registeredPeriods: updated, clearMessages: true);
  }

  Future<bool> saveSchedule() async {
    if (state.registeredPeriods.length < 3) {
      state = state.copyWith(
        errorMessage:
            'Vui lòng chọn tối thiểu 3 buổi rảnh mỗi tuần (Sáng / Chiều / Tối).',
      );
      return false;
    }
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final repository = ref.read(mentorRepositoryProvider);
      final success = await repository.saveWeeklySchedule(
        weekStart: state.selectedWeekMonday,
        periods: state.registeredPeriods.toList(),
      );
      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage:
              'Đã lưu đăng ký lịch dạy thành công! Chờ Admin xếp tiết và công bố.',
        );
        await loadSchedule(clearMessages: false);
        ref.invalidate(mentorAvailabilityControllerProvider);
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Không thể lưu đăng ký lịch dạy. Vui lòng thử lại.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Không thể lưu đăng ký lịch dạy: $e',
      );
      return false;
    }
  }
}

class MentorAvailabilityController
    extends AsyncNotifier<List<MentorAvailabilitySlot>> {
  @override
  Future<List<MentorAvailabilitySlot>> build() {
    return ref.watch(mentorRepositoryProvider).loadAvailability();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<MentorAvailabilitySlot>>();
    state = await AsyncValue.guard(build);
  }
}

class MentorMeetingsController
    extends AsyncNotifier<List<MentorMeetingSummary>> {
  @override
  Future<List<MentorMeetingSummary>> build() {
    return ref.watch(mentorRepositoryProvider).loadMeetings();
  }

  Future<void> retry() async {
    state = const AsyncLoading<List<MentorMeetingSummary>>();
    state = await AsyncValue.guard(build);
  }

  /// Mentor hủy lịch hẹn tư vấn: tự động hoàn 1 lượt tín dụng cho học viên.
  Future<bool> cancelMeeting(int bookingId, String reason) async {
    try {
      final ok = await ref.read(mentorRepositoryProvider).cancelMeeting(bookingId, reason);
      if (ok) ref.invalidateSelf();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Mentor gửi phản hồi cho đánh giá của học viên.
  Future<bool> replyReview(int reviewId, String reply) async {
    try {
      final ok = await ref.read(mentorRepositoryProvider).replyReview(reviewId, reply);
      if (ok) ref.invalidateSelf();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Mentor gửi giải trình phản hồi khiếu nại của học viên.
  Future<bool> respondDispute(int disputeId, String responseText) async {
    try {
      final ok = await ref.read(mentorRepositoryProvider).respondDispute(disputeId, responseText);
      if (ok) ref.invalidateSelf();
      return ok;
    } catch (_) {
      return false;
    }
  }
}

class MentorProfileController extends AsyncNotifier<MentorProfileData> {
  @override
  Future<MentorProfileData> build() {
    return ref.watch(mentorRepositoryProvider).loadProfile();
  }

  Future<void> retry() async {
    state = const AsyncLoading<MentorProfileData>();
    state = await AsyncValue.guard(build);
  }

  Future<bool> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async {
    try {
      final updated = await ref.read(mentorRepositoryProvider).updateProfile(
        bio: bio,
        expertise: expertise,
        jlptLevel: jlptLevel,
        yearsOfExperience: yearsOfExperience,
        workplace: workplace,
        verificationDocumentUrl: verificationDocumentUrl,
        introductionVideoUrl: introductionVideoUrl,
      );
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async {
    try {
      final updated = await ref.read(mentorRepositoryProvider).submitVerification(
        verificationDocumentUrl: verificationDocumentUrl,
        notes: notes,
      );
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final updated = await ref.read(mentorRepositoryProvider)
          .uploadVerificationDocument(bytes: bytes, fileName: fileName);
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

Future<void> refreshMentorReadModels(WidgetRef ref) async {
  Future<void> settle(Future<Object?> request) async {
    try {
      await request;
    } catch (_) {
      // Each read model owns and renders its failure independently.
    }
  }

  await Future.wait(<Future<void>>[
    settle(ref.refresh(mentorAvailabilityControllerProvider.future)),
    settle(ref.refresh(mentorMeetingsControllerProvider.future)),
    settle(
      ref.read(mentorWeeklyScheduleControllerProvider.notifier).loadSchedule(),
    ),
  ]);
}
