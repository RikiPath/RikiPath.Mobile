enum MeetingParticipantRole {
  mentor,
  learner;

  static MeetingParticipantRole fromApi(Object? value) {
    return value?.toString().trim().toLowerCase() == 'mentor'
        ? MeetingParticipantRole.mentor
        : MeetingParticipantRole.learner;
  }

  String get apiValue => switch (this) {
    MeetingParticipantRole.mentor => 'Mentor',
    MeetingParticipantRole.learner => 'Learner',
  };
}
