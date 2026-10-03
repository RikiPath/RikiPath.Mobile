enum BackendUserRole {
  learner('Learner', isMobileSupported: true),
  contentAuthor('ContentAuthor'),
  mentor('Mentor', isMobileSupported: true),
  admin('Admin');

  const BackendUserRole(this.apiValue, {this.isMobileSupported = false});

  final String apiValue;
  final bool isMobileSupported;

  static BackendUserRole? fromApiValue(String value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}
