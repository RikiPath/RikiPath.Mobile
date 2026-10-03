enum MockTestAttemptStatus {
  inProgress('in_progress'),
  completed('completed');

  const MockTestAttemptStatus(this.apiValue);

  final String apiValue;

  static MockTestAttemptStatus? fromApiValue(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
