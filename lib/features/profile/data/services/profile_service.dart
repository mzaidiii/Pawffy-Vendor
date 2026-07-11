import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';
import '../models/vendor_profile_model.dart';

class ProfileService {
  final Dio _dio = DioClient.dio;

  Future<Options> _getOptions() async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<VendorProfileModel> getProfile({String period = 'month'}) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        '/api/vendor/profile',
        queryParameters: {'period': period},
        options: options,
      );
      return VendorProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load profile data',
      );
    }
  }

  Future<List<VendorServiceModel>> getServices() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        '/api/vendor/services',
        options: options,
      );
      final body = response.data;
      final List<dynamic> data = (body is Map && body['data'] != null)
          ? body['data']
          : (body is List ? body : []);
      return data.map((json) => VendorServiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load services list',
      );
    }
  }

  Future<void> addService({
    required String serviceType,
    required String name,
    required String description,
    required List<String> inclusions,
    required int durationMinutes,
    required String priceType,
    double? price,
    double? minPrice,
    double? maxPrice,
    required String serviceLocation,
  }) async {
    try {
      final options = await _getOptions();
      final payload = {
        'serviceType': serviceType,
        'name': name,
        'description': description,
        'inclusions': inclusions,
        'durationMinutes': durationMinutes,
        'priceType': priceType,
        if (price != null) 'price': price,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        'serviceLocation': serviceLocation,
      };

      await _dio.post(
        '/api/vendor/services',
        data: payload,
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add service',
      );
    }
  }

  Future<void> updateService({
    required String serviceId,
    required String serviceType,
    required String name,
    required String description,
    required List<String> inclusions,
    required int durationMinutes,
    required String priceType,
    double? price,
    double? minPrice,
    double? maxPrice,
    required String serviceLocation,
  }) async {
    try {
      final options = await _getOptions();
      final payload = {
        'serviceType': serviceType,
        'name': name,
        'description': description,
        'inclusions': inclusions,
        'durationMinutes': durationMinutes,
        'priceType': priceType,
        if (price != null) 'price': price,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        'serviceLocation': serviceLocation,
      };

      await _dio.put(
        '/api/vendor/services/$serviceId',
        data: payload,
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update service',
      );
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      final options = await _getOptions();
      await _dio.delete(
        '/api/vendor/services/$serviceId',
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete service',
      );
    }
  }

  Future<void> updateProfile({
    required String contactName,
    required String businessName,
    required String phone,
    required String location,
    required String city,
    required String state,
    required String profileTitle,
    required String description,
    String? dob,
    String? gender,
    String? pinCode,
  }) async {
    try {
      final options = await _getOptions();
      await _dio.put(
        ApiConstants.profileUpdate,
        data: {
          'contactName': contactName,
          'businessName': businessName,
          'phone': phone,
          'location': location,
          'city': city,
          'state': state,
          'profileTitle': profileTitle,
          'description': description,
          if (dob != null) 'dob': dob,
          if (gender != null) 'gender': gender,
          if (pinCode != null) 'pinCode': pinCode,
        },
        options: options,
       );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    try {
      final options = await _getOptions();
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      await _dio.post(
        ApiConstants.profileAvatar,
        data: formData,
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload avatar',
      );
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.preferencesNotifications,
        options: options,
      );
      final body = response.data;
      return (body is Map && body['data'] != null)
          ? body['data']
          : (body is Map ? body : {});
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load notification preferences',
      );
    }
  }

  Future<void> updateNotificationPreferences({
    required bool pushRequests,
    required bool pushMessages,
    required bool emailMarketing,
    required bool smsAlerts,
  }) async {
    try {
      final options = await _getOptions();
      await _dio.put(
        ApiConstants.preferencesNotifications,
        data: {
          'pushRequests': pushRequests,
          'pushMessages': pushMessages,
          'emailMarketing': emailMarketing,
          'smsAlerts': smsAlerts,
        },
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update notification preferences',
      );
    }
  }

  Future<void> createSupportTicket({
    required String subject,
    required String category,
    required String description,
  }) async {
    try {
      final options = await _getOptions();
      await _dio.post(
        ApiConstants.supportTickets,
        data: {
          'subject': subject,
          'category': category,
          'description': description,
        },
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit support ticket',
      );
    }
  }
}
