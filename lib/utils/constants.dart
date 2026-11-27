class AppConstants {
  static const String appName = 'Turnly';

  // Collections
  static const String users = 'users';
  static const String hospitals = 'hospitals';
  static const String departments = 'departments';
  static const String doctors = 'doctors';
  static const String tokens = 'tokens';
  static const String familyMembers = 'familyMembers'; // sub-collection under users
  static const String fcmTokens = 'fcmTokens';

  // Roles
  static const String rolePatient = 'patient';
  static const String roleManager = 'manager';
  static const String roleAdmin = 'admin';

  // Hospital status
  static const String hospitalPending = 'pending';
  static const String hospitalApproved = 'approved';
  static const String hospitalRejected = 'rejected';
  static const String hospitalSuspended = 'suspended';

  // Token status
  static const String tokenWaiting = 'waiting';
  static const String tokenServing = 'serving';
  static const String tokenDone = 'done';
  static const String tokenCancelled = 'cancelled';
  static const String tokenSkipped = 'skipped';
}
