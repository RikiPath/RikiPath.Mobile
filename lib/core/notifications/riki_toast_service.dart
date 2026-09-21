import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RikiToastType { success, error, warning, info }

@immutable
class RikiToastData {
  const RikiToastData({
    required this.id,
    required this.type,
    required this.title,
    required this.duration,
    this.description,
  });

  final int id;
  final RikiToastType type;
  final String title;
  final String? description;
  final Duration duration;
}

final rikiToastServiceProvider =
    NotifierProvider<RikiToastService, List<RikiToastData>>(
      RikiToastService.new,
    );

class RikiToastService extends Notifier<List<RikiToastData>> {
  static const successDuration = Duration(milliseconds: 2800);
  static const infoDuration = Duration(milliseconds: 3000);
  static const warningDuration = Duration(milliseconds: 3600);
  static const errorDuration = Duration(milliseconds: 4000);
  static const _maximumVisibleToasts = 3;

  int _nextId = 0;

  @override
  List<RikiToastData> build() => const [];

  int success({
    required String title,
    String? description,
    Duration duration = successDuration,
  }) {
    return show(
      type: RikiToastType.success,
      title: title,
      description: description,
      duration: duration,
    );
  }

  int error({
    required String title,
    String? description,
    Duration duration = errorDuration,
  }) {
    return show(
      type: RikiToastType.error,
      title: title,
      description: description,
      duration: duration,
    );
  }

  int warning({
    required String title,
    String? description,
    Duration duration = warningDuration,
  }) {
    return show(
      type: RikiToastType.warning,
      title: title,
      description: description,
      duration: duration,
    );
  }

  int info({
    required String title,
    String? description,
    Duration duration = infoDuration,
  }) {
    return show(
      type: RikiToastType.info,
      title: title,
      description: description,
      duration: duration,
    );
  }

  int show({
    required RikiToastType type,
    required String title,
    String? description,
    Duration? duration,
  }) {
    final id = _nextId++;
    final toast = RikiToastData(
      id: id,
      type: type,
      title: title,
      description: description,
      duration: duration ?? _durationFor(type),
    );
    final retained = state.length >= _maximumVisibleToasts
        ? state.sublist(state.length - (_maximumVisibleToasts - 1))
        : state;
    state = [...retained, toast];
    return id;
  }

  void dismiss(int id) {
    if (!state.any((toast) => toast.id == id)) return;
    state = [
      for (final toast in state)
        if (toast.id != id) toast,
    ];
  }

  Duration _durationFor(RikiToastType type) => switch (type) {
    RikiToastType.success => successDuration,
    RikiToastType.error => errorDuration,
    RikiToastType.warning => warningDuration,
    RikiToastType.info => infoDuration,
  };
}
