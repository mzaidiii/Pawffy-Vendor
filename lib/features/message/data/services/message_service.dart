import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';
import '../models/message_model.dart';

class MessageService {
  final Dio _dio = DioClient.dio;

  Future<Options> _getOptions() async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.conversations,
        options: options,
      );
      final dynamic body = response.data;
      final List<dynamic> data = (body is Map && body['data'] != null)
          ? body['data']
          : (body is List ? body : []);
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load conversations',
      );
    }
  }

  Future<String> startOrGetConversation(String receiverId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.startChat(receiverId),
        options: options,
      );
      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        // Direct checks
        if (body['conversationId'] != null) {
          return body['conversationId'].toString();
        }
        if (body['id'] != null) {
          return body['id'].toString();
        }
        if (body['_id'] != null) {
          return body['_id'].toString();
        }

        // Nested 'data' checks
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          if (data['conversationId'] != null) {
            return data['conversationId'].toString();
          }
          if (data['id'] != null) {
            return data['id'].toString();
          }
          if (data['_id'] != null) {
            return data['_id'].toString();
          }
        }
      }
      throw Exception('Conversation ID not found in response');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to start conversation',
      );
    }
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.messagesByConversation(conversationId),
        options: options,
      );
      final dynamic body = response.data;
      if (body is List) {
        return body;
      }
      if (body is Map && body['data'] != null) {
        return body['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load messages');
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final options = await _getOptions();
      await _dio.post(
        ApiConstants.sendMessage,
        data: {'receiverId': receiverId, 'content': content},
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send message');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      final options = await _getOptions();
      await _dio.patch(
        ApiConstants.markConversationRead(conversationId),
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to mark messages as read',
      );
    }
  }
}
