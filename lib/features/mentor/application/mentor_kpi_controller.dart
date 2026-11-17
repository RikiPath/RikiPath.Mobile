import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mentor/data/api_mentor_kpi_repository.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_kpi_repository.dart';

enum MentorKpiPreset { currentMonth, last30Days, last90Days }

@immutable
class MentorKpiDateWindow {
  const MentorKpiDateWindow({
    required this.preset,
    required this.fromDate,
    required this.toDate,
  });

  factory MentorKpiDateWindow.fromPreset(MentorKpiPreset preset) {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final to = fmt.format(now);
    final DateTime fromDt = switch (preset) {
      MentorKpiPreset.currentMonth => DateTime(now.year, now.month, 1),
      MentorKpiPreset.last30Days => now.subtract(const Duration(days: 29)),
      MentorKpiPreset.last90Days => DateTime(now.year, now.month - 2, 1),
    };
    return MentorKpiDateWindow(
      preset: preset,
      fromDate: fmt.format(fromDt),
      toDate: to,
    );
  }

  final MentorKpiPreset preset;
  final String fromDate;
  final String toDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorKpiDateWindow &&
          preset == other.preset &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(preset, fromDate, toDate);
}

final mentorKpiRepositoryProvider = Provider<MentorKpiRepository>(
  (ref) => ApiMentorKpiRepository(ref.watch(apiClientProvider)),
);

class MentorKpiPresetNotifier extends Notifier<MentorKpiPreset> {
  @override
  MentorKpiPreset build() => MentorKpiPreset.last90Days;

  void select(MentorKpiPreset preset) {
    state = preset;
  }
}

final mentorKpiPresetProvider =
    NotifierProvider<MentorKpiPresetNotifier, MentorKpiPreset>(
      MentorKpiPresetNotifier.new,
    );

final mentorKpiSummaryProvider = FutureProvider.autoDispose<MentorKpiSummary>((
  ref,
) {
  final preset = ref.watch(mentorKpiPresetProvider);
  final window = MentorKpiDateWindow.fromPreset(preset);
  return ref
      .watch(mentorKpiRepositoryProvider)
      .loadSummary(fromDate: window.fromDate, toDate: window.toDate);
});
