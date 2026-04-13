/// API endpoints for the Futsmandu Owner app.
class OwnerApiConfig {
  OwnerApiConfig._();

  // ---------------------------------------------------------------------------
  // BASE
  // ---------------------------------------------------------------------------

  // static const String baseUrl = String.fromEnvironment(
  //     'OWNER_API_BASE_URL',
  //     defaultValue: 'https://aloof-word-tuition.ngrok-free.dev',
  // );
  static const String baseUrl = String.fromEnvironment(
    'OWNER_API_BASE_URL',
    defaultValue: 'http://localhost:3002/',
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

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  static const String registerEndpoint = '$authEndpoint/register';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String verifyOtpEndpoint = '$authEndpoint/verify-otp';
  static const String resendOtpEndpoint = '$authEndpoint/resend-otp';
  static const String refreshEndpoint = '$authEndpoint/refresh';
  static const String logoutEndpoint = '$authEndpoint/logout';

  // ---------------------------------------------------------------------------
  // BOOKINGS
  // ---------------------------------------------------------------------------

  static const String listBookingsEndpoint = bookingsEndpoint;
  static const String createOfflineBookingEndpoint =
      '$bookingsEndpoint/offline';

  static String bookingDetailEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId';

  static String markAttendanceEndpoint(String bookingId) =>
      '$bookingsEndpoint/$bookingId/attendance';

  static String bookingCalendarEndpoint(String courtId) =>
      '$bookingsEndpoint/courts/$courtId/calendar';

  // ❌ REMOVED DUPLICATE FUNCTION (was redundant)
  // static String bookingAttendanceEndpoint ...

  // ---------------------------------------------------------------------------
  // COURTS
  // ---------------------------------------------------------------------------

  static String courtCalendarEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/calendar';

  static String blockCourtSlotEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/blocks';

  static String unblockCourtSlotEndpoint(String blockId) =>
      '$courtsEndpoint/blocks/$blockId';


  // ---------------------------------------------------------------------------
  // PRICING
  // ---------------------------------------------------------------------------

  static String pricingRulesEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/pricing';

  static String pricingRuleEndpoint(String ruleId) =>
      '$pricingEndpoint/$ruleId';

  static String pricingPreviewEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId/pricing/preview';

  // ---------------------------------------------------------------------------
  // VENUES
  // ---------------------------------------------------------------------------

  static String venueEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId';

  static String venueCourtsEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/courts';

  static String courtEndpoint(String courtId) =>
      '$courtsEndpoint/$courtId';

  static String venueGalleryEndpoint(String venueId) =>
      '$venuesEndpoint/$venueId/gallery';

  // ---------------------------------------------------------------------------
  // MEDIA - STEP 1 (UPLOAD URLS)
  // ---------------------------------------------------------------------------

  static const String mediaKycUploadUrlEndpoint =
      '$mediaEndpoint/kyc/upload-url';

  static const String mediaAvatarUploadUrlEndpoint =
      '$mediaEndpoint/profile/avatar/upload-url';

  static String venueCoverUploadUrlEndpoint(String venueId) =>
      '$mediaEndpoint/venues/$venueId/cover/upload-url';

  static String venueGalleryUploadUrlEndpoint(String venueId) =>
      '$mediaEndpoint/venues/$venueId/gallery/upload-url';

  static String venueVerificationUploadUrlEndpoint(String venueId) =>
      '$mediaEndpoint/venues/$venueId/verification/upload-url';

  // ---------------------------------------------------------------------------
  // MEDIA - STEP 2 (CONFIRM + STATUS)
  // ---------------------------------------------------------------------------

  static const String mediaConfirmUploadEndpoint =
      '$mediaEndpoint/confirm-upload';

  static String mediaStatusEndpoint(String assetId) =>
      '$mediaEndpoint/status/$assetId';

  // ---------------------------------------------------------------------------
  // MEDIA - PRIVATE ACCESS
  // ---------------------------------------------------------------------------

  static const String mediaDownloadUrlEndpoint =
      '$mediaEndpoint/download-url';

  static String mediaDeleteAssetEndpoint(String assetId) =>
      '$mediaEndpoint/asset?assetId=$assetId';

  static const String mediaKycListEndpoint = '$mediaEndpoint/kyc';
}