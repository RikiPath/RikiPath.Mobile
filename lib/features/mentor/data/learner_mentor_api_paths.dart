abstract final class LearnerMentorApiPaths {
  static const String root = '/api/mentor-meetings';
  static const String mentors = '$root/mentors';
  static const String plans = '$root/plans';
  static const String availability = '$root/availability';
  static const String purchase = '$root/purchase';
  static const String bookings = '$root/bookings';

  static String subscriptionBookings(int subscriptionId) =>
      '$root/subscriptions/$subscriptionId/bookings';

  static String purchaseStatus(int subscriptionId) =>
      '$root/purchases/$subscriptionId';

  static String syncPurchase(int subscriptionId) =>
      '$root/purchases/$subscriptionId/sync';
}
