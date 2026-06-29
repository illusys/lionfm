import '../../models/station.dart';

class BillingPlans {
  BillingPlans._();

  /// Monthly price in NGN (display only). Kobo amounts live in Cloud Functions.
  static const Map<String, int> monthlyNGN = {
    'free':       0,
    'starter':    15000,
    'pro':        35000,
    'enterprise': 100000,
  };

  static int priceForPlan(StationPlan plan) => switch (plan) {
        StationPlan.free => 0,
        StationPlan.starter => 15000,
        StationPlan.pro => 35000,
        StationPlan.enterprise => 100000,
      };

  static String planKey(StationPlan plan) => switch (plan) {
        StationPlan.free => 'free',
        StationPlan.starter => 'starter',
        StationPlan.pro => 'pro',
        StationPlan.enterprise => 'enterprise',
      };
}
