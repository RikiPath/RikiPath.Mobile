import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_essay_writing_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

final essayWritingRepositoryProvider = Provider<EssayWritingRepository>((ref) {
  return ApiEssayWritingRepository(ref.watch(apiClientProvider));
});

// Kept in memory across navigation; never persist an unpublished learner essay
// in shared preferences or send it until the learner explicitly submits.
final essayWritingDraftProvider = StateProvider<String>((ref) => '');
