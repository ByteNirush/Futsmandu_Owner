/// API endpoints for the Futsmandu Owner app.
class OwnerApiConfig {
  OwnerApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'OWNER_API_BASE_URL',
    defaultValue: 'http://localhost:3002',
  );

  static const String apiPrefix = '/api/v1/owner';
  static const String authEndpoint = '$apiPrefix/auth';
  static const String bookingsEndpoint = '$apiPrefix/bookings';
  static const String courtsEndpoint = '$apiPrefix/courts';
  static const String venuesEndpoint = '$apiPrefix/venues';
  static const String staffEndpoint = '$apiPrefix/staff';
  static const String pricingEndpoint = '$apiPrefix/pricing';
  static const String analyticsEndpoint = '$apiPrefix/analytics';
    static const String mediaEndpoint = '$apiPrefix/media';

  static const String healthEndpoint = '$apiPrefix/health';

  static const String registerEndpoint = '$authEndpoint/register';
  static const String loginEndpoint = '$authEndpoint/login';
    static const String verifyOtpEndpoint = '$authEndpoint/verify-otp';
    static const String resendOtpEndpoint = '$authEndpoint/resend-otp';
  static const String refreshEndpoint = '$authEndpoint/refresh';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String uploadDocsEndpoint = '$authEndpoint/upload-docs';

  static const String listBookingsEndpoint = bookingsEndpoint;
  static const String createOfflineBookingEndpoint =
      '$bookingsEndpoint/offline';

  static String bookingDetailEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId';

  static String markAttendanceEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId/attendance';

  static String bookingCalendarEndpoint(String courtId) =>
      '$bookingsEndpoint/courts/$courtId/calendar';

  static String offlineBookingEndpoint() => '$bookingsEndpoint/offline';

  static String bookingAttendanceEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId/attendance';

  static String courtCalendarEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/calendar';

  static String blockCourtSlotEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/blocks';

  static String unblockCourtSlotEndpoint(String blockId) =>
      '$courtsEndpoint/blocks/$blockId';

  static String courtBookingCalendarEndpoint(String courtId) =>
      bookingCalendarEndpoint(courtId);

  static String pricingRulesEndpoint(String courtId) =>
      '$apiPrefix/courts/$courtId/pricing';

  static String pricingRuleEndpoint(String ruleId) =>
      '$pricingEndpoint/$ruleId';

  static String pricingPreviewEndpoint(String courtId) =>
      '$apiPrefix/courts/$courtId/pricing/preview';

  static String ownerVenueEndpoint(String venueId) => '$venuesEndpoint/$venueId';

  static String ownerVenueCourtsEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/courts';

  static String ownerCourtEndpoint(String courtId) => '$courtsEndpoint/$courtId';

  static String venueImageUploadUrlEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/images/upload-url';

  static String venueImageConfirmEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/images/confirm';

  static String venueCoverUploadUrlEndpoint(String venueId) =>
      '$mediaEndpoint/venues/$venueId/images/cover/upload-url';

  static const String mediaUploadUrlEndpoint = '$mediaEndpoint/upload-url';
  static const String mediaConfirmUploadEndpoint =
      '$mediaEndpoint/confirm-upload';
  static String mediaStatusEndpoint(String assetId) =>
      '$mediaEndpoint/status/$assetId';
  static const String mediaDeleteAssetEndpoint = '$mediaEndpoint/asset';
}
