class ApiConstants {
  static const String baseUrl = 'https://pawffy-backend.onrender.com';

  // Auth
  static const String login = '/api/auth/vendor/login';
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
}
