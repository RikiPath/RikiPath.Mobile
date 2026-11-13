import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RikiToastType { success, error, warning, info, celebration }

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
  static const celebrationDuration = Duration(milliseconds: 1600);
  static const _maximumQueuedToasts = 2;

  int _nextId = 0;
  final List<RikiToastData> _pending = [];

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

  int celebrate({required String title, String? description}) => show(
    type: RikiToastType.celebration,
    title: title,
    description: description,
    duration: celebrationDuration,
  );

  int show({
    required RikiToastType type,
    required String title,
    String? description,
    Duration? duration,
  }) {
    for (final existing in [...state, ..._pending]) {
      if (existing.type == type &&
          existing.title == title &&
          existing.description == description) {
        return existing.id;
      }
    }
    final id = _nextId++;
    final toast = RikiToastData(
      id: id,
      type: type,
      title: title,
      description: description,
      duration: duration ?? _durationFor(type),
    );
    if (state.isEmpty || _priority(type) >= _priority(state.first.type)) {
      state = [toast];
    } else if (_pending.length < _maximumQueuedToasts) {
      _pending.add(toast);
    }
    return id;
  }

  void dismiss(int id) {
    if (state.any((toast) => toast.id == id)) {
      state = _pending.isEmpty ? const [] : [_pending.removeAt(0)];
    } else {
      _pending.removeWhere((toast) => toast.id == id);
    }
  }

  void clear() {
    _pending.clear();
    state = const [];
  }

  int _priority(RikiToastType type) => switch (type) {
    RikiToastType.error => 3,
    RikiToastType.warning => 2,
    RikiToastType.celebration => 2,
    RikiToastType.success => 1,
    RikiToastType.info => 0,
  };

  Duration _durationFor(RikiToastType type) => switch (type) {
    RikiToastType.success => successDuration,
    RikiToastType.error => errorDuration,
    RikiToastType.warning => warningDuration,
    RikiToastType.info => infoDuration,
    RikiToastType.celebration => celebrationDuration,
  };
}
