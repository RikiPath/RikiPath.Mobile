import 'package:flutter/widgets.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

extension LocalizedLearningSkillCategory on LearningSkillCategory {
  String localizedLabel(BuildContext context) => switch (this) {
    LearningSkillCategory.vocabulary => context.l10n.skillVocabulary,
    LearningSkillCategory.kanji => context.l10n.skillKanji,
    LearningSkillCategory.grammar => context.l10n.skillGrammar,
    LearningSkillCategory.reading => context.l10n.skillReading,
    LearningSkillCategory.listening => context.l10n.skillListening,
  };

  String localizedUnit(BuildContext context) => switch (this) {
    LearningSkillCategory.vocabulary => context.l10n.unitWords,
    LearningSkillCategory.kanji => context.l10n.unitCharacters,
    LearningSkillCategory.grammar ||
    LearningSkillCategory.reading ||
    LearningSkillCategory.listening => context.l10n.unitLessons,
  };
}
