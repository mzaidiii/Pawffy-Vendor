import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<NotificationModel>> getNotifications({bool? unreadOnly}) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: unreadOnly == true ? {'unread': true} : null,
        options: await _authHeader,
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch notifications',
      );
    }
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _dio.patch(
        ApiConstants.markNotificationRead(notifId),
        options: await _authHeader,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark as read');
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch(
        ApiConstants.markAllNotificationsRead,
        options: await _authHeader,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to mark all as read',
      );
    }
  }

  Future<void> deleteNotification(String notifId) async {
    try {
      await _dio.delete(
        ApiConstants.deleteNotification(notifId),
        options: await _authHeader,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete notification',
      );
    }
  }
}
