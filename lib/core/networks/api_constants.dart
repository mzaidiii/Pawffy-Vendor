class ApiConstants {
  static const String baseUrl = 'https://pawffy-backend-yyed.onrender.com';

  // Auth
  static const String session = '/api/auth/session';
  static const String register = '/api/auth/vendor/register';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String markAllNotificationsRead = '/api/notifications/read-all';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static String deleteNotification(String id) => '/api/notifications/$id';

  // Messages
  static const String conversations = '/api/messages/conversations';
  static const String vendorChats = '/api/vendor/chats';
  static const String sendMessage = '/api/messages';
  static String startChat(String receiverId) =>
      '/api/messages/conversation/with/$receiverId';
  static String messagesByConversation(String id) => '/api/messages/$id';
  static String markConversationRead(String id) => '/api/messages/$id/read';
  //  Onboarding
  static const String onboarding = '/api/vendor/onboarding';
  static const String onboardingBusiness = '/api/vendor/onboarding/business';
  static const String onboardingServices = '/api/vendor/onboarding/services';
  static String onboardingServiceById(String id) =>
      '/api/vendor/onboarding/services/$id';
  static const String onboardingAvailability =
      '/api/vendor/onboarding/availability';
  static const String onboardingDocuments = '/api/vendor/onboarding/documents';
  static String onboardingDocumentById(String id) =>
      '/api/vendor/onboarding/documents/$id';
  static const String onboardingReview = '/api/vendor/onboarding/review';
  static const String onboardingSubmit = '/api/vendor/onboarding/submit';
  static const String vendorDashboard = '/api/vendor/dashboard';

  // Home
  static const String home = '/api/vendor/home';
  static const String status = '/api/vendor/status';
  static const String notificationsUnreadCount =
      '/api/vendor/notifications/unread-count';

  // Calendar
  static const String calendar = '/api/vendor/calendar';
  static const String blockedDates = '/api/vendor/blocked-dates';
  static String deleteBlockedDate(String id) => '/api/vendor/blocked-dates/$id';
  static const String availability = '/api/vendor/availability';

  // Requests
  static const String requests = '/api/vendor/requests';
  static String acceptRequest(String id) => '/api/vendor/requests/$id/accept';
  static String rejectRequest(String id) => '/api/vendor/requests/$id/reject';
  static String startRequest(String id) => '/api/vendor/requests/$id/start';
  static String updateRequestProgress(String id) => '/api/vendor/requests/$id/progress';
  static String uploadRequestMedia(String id) => '/api/vendor/requests/$id/media';
  static String updateRequestLocation(String id) => '/api/vendor/requests/$id/location';
  static String completeRequest(String id) => '/api/vendor/requests/$id/complete';

  // Settings & Security
  static const String requestEmailChange = '/api/vendor/email/request-update';
  static const String verifyEmailChange = '/api/vendor/email/verify-update';
  static const String requestPhoneChange = '/api/vendor/phone/request-update';
  static const String verifyPhoneChange = '/api/vendor/phone/verify-update';
  static const String profileUpdate = '/api/vendor/profile';
  static const String profileAvatar = '/api/vendor/profile/avatar';
  static const String preferencesNotifications = '/api/vendor/preferences/notifications';
  static const String supportTickets = '/api/support/tickets';
  static const String wallet = '/api/wallet';
  static const String withdraw = '/api/wallet/withdraw';
  static const String terms = '/api/static/terms';
  static const String privacy = '/api/static/privacy';

  // Stripe Payouts
  static const String payoutsCheck = '/api/vendor/payouts/check';
  static const String payoutsOnboard = '/api/vendor/payouts/onboard';
  static const String payoutsStatus = '/api/vendor/payouts/status';

  // Reviews
  static const String vendorReviews = '/api/vendor/reviews';
  static String replyToReview(String reviewId) => '/api/vendor/reviews/$reviewId/reply';
  static const String customerReviews = '/api/vendor/customer-reviews';
}
