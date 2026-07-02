class ApiConstants {
  static const String baseUrl = 'https://pawffy-backend.onrender.com';

  // ── Auth ──────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';

  // ── Notifications ─────────────────────────────────
  static const String notifications = '/api/notifications';
  static const String markAllNotificationsRead = '/api/notifications/read-all';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static String deleteNotification(String id) => '/api/notifications/$id';

  // ── Messages ──────────────────────────────────────
  static const String conversations = '/api/messages/conversations';
  static const String sendMessage = '/api/messages';
  static String startChat(String receiverId) =>
      '/api/messages/conversation/with/$receiverId';
  static String messagesByConversation(String id) => '/api/messages/$id';
  static String markConversationRead(String id) => '/api/messages/$id/read';
}
