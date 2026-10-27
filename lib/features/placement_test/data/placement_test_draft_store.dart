import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';

final placementTestDraftStoreProvider = Provider<PlacementTestDraftStore>(
  (ref) => PlacementTestDraftStore(ref.watch(jsonPreferenceStoreProvider)),
);

@immutable
class PlacementTestDraft {
  const PlacementTestDraft({
    required this.schemaVersion,
    required this.userId,
    required this.attemptId,
    required this.currentQuestionIndex,
    required this.selectedOptionIdsByQuestionId,
    required this.updatedAt,
  });

  static const int currentSchemaVersion = 1;

  factory PlacementTestDraft.fromJson(Map<String, Object?> json) {
    final rawSelections = json['selectedOptionIdsByQuestionId'];
    if (rawSelections is! Map<Object?, Object?>) {
      throw const FormatException('Invalid Placement Test draft selections.');
    }
    final selections = <int, int>{};
    for (final entry in rawSelections.entries) {
      final questionId = int.tryParse(entry.key.toString());
      final optionId = entry.value;
      if (questionId == null || questionId <= 0 || optionId is! int) {
        throw const FormatException('Invalid Placement Test draft selection.');
      }
      selections[questionId] = optionId;
    }

    final updatedAtValue = json['updatedAt'];
    final updatedAt = updatedAtValue is String
        ? DateTime.tryParse(updatedAtValue)?.toUtc()
        : null;
    if (json['schemaVersion'] is! int ||
        json['userId'] is! int ||
        json['attemptId'] is! int ||
        json['currentQuestionIndex'] is! int ||
        updatedAt == null) {
      throw const FormatException('Invalid Placement Test draft.');
    }

    return PlacementTestDraft(
      schemaVersion: json['schemaVersion']! as int,
      userId: json['userId']! as int,
      attemptId: json['attemptId']! as int,
      currentQuestionIndex: json['currentQuestionIndex']! as int,
      selectedOptionIdsByQuestionId: Map<int, int>.unmodifiable(selections),
      updatedAt: updatedAt,
    );
  }

  final int schemaVersion;
  final int userId;
  final int attemptId;
  final int currentQuestionIndex;
  final Map<int, int> selectedOptionIdsByQuestionId;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'userId': userId,
    'attemptId': attemptId,
    'currentQuestionIndex': currentQuestionIndex,
    'selectedOptionIdsByQuestionId': selectedOptionIdsByQuestionId.map(
      (questionId, optionId) => MapEntry(questionId.toString(), optionId),
    ),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class PlacementTestDraftStore {
  const PlacementTestDraftStore(this._preferences);

  final JsonPreferenceStore _preferences;

  static String keyFor({required int userId, required int attemptId}) =>
      'placement_draft_v1:$userId:$attemptId';

  static String dismissedKeyFor({required int userId}) =>
      'placement_dismissed_v1:$userId';

  Future<int?> loadDismissedAttemptId({required int userId}) async {
    final key = dismissedKeyFor(userId: userId);
    final raw = await _preferences.read(key);
    if (raw == null) return null;
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      await _preferences.remove(key);
      return null;
    }
    return parsed;
  }

  Future<void> saveDismissedAttemptId({
    required int userId,
    required int attemptId,
  }) {
    final key = dismissedKeyFor(userId: userId);
    return _preferences.write(key, attemptId.toString());
  }

  Future<bool> isResultDismissed({
    required int userId,
    required int attemptId,
  }) async {
    final dismissedId = await loadDismissedAttemptId(userId: userId);
    return dismissedId == attemptId;
  }

  Future<void> clearDismissedAttemptId({required int userId}) {
    return _preferences.remove(dismissedKeyFor(userId: userId));
  }

  Future<PlacementTestDraft?> load({
    required int userId,
    required int attemptId,
  }) async {
    final key = keyFor(userId: userId, attemptId: attemptId);
    final raw = await _preferences.read(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        throw const FormatException('Invalid Placement Test draft payload.');
      }
      final draft = PlacementTestDraft.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (draft.schemaVersion != PlacementTestDraft.currentSchemaVersion ||
          draft.userId != userId ||
          draft.attemptId != attemptId) {
        await _preferences.remove(key);
        return null;
      }
      return draft;
    } on FormatException {
      await _preferences.remove(key);
      return null;
    }
  }

  Future<void> save(PlacementTestDraft draft) {
    final key = keyFor(userId: draft.userId, attemptId: draft.attemptId);
    return _preferences.write(key, jsonEncode(draft.toJson()));
  }

  Future<void> clear({required int userId, required int attemptId}) {
    return _preferences.remove(keyFor(userId: userId, attemptId: attemptId));
  }
}
