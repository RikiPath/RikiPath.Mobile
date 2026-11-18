import 'package:flutter/foundation.dart';

@immutable
class BookableMentor {
  const BookableMentor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.headline,
    this.bio,
    this.jlptLevels = const [],
    this.teachingMethod,
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final List<String> jlptLevels;
  final String? teachingMethod;

  List<String> get teachingJlptLevels => jlptLevels;
}
