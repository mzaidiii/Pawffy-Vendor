import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';

class OnboardingService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> getOnboardingState() async {
    try {
      final options = await _authHeader;
      final response = await _dio.get(
        ApiConstants.onboarding,
        options: options,
      );

      if (response.data != null && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Invalid response structure'};
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to get onboarding state',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> saveBusinessInfo({
    required String businessName,
    required String contactName,
    required String phone,
    required String location,
    required String description,
  }) async {
    try {
      final payload = {
        'businessName': businessName,
        'contactName': contactName,
        'phone': phone,
        'location': location,
        'description': description,
      };
      final options = await _authHeader;
      final response = await _dio.put(
        ApiConstants.onboardingBusiness,
        data: payload,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to save business info',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> addService({
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
      final payload = {
        'serviceType': serviceType,
        'name': name,
        'description': description,
        'inclusions': inclusions,
        'durationMinutes': durationMinutes,
        'priceType': priceType,
        if (priceType == 'fixed') 'price': price,
        if (priceType == 'range') ...{
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        },
        'serviceLocation': serviceLocation,
      };
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.onboardingServices,
        data: payload,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add service');
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    required String name,
    required String priceType,
    double? price,
    double? minPrice,
    double? maxPrice,
    required int durationMinutes,
  }) async {
    try {
      final payload = {
        'name': name,
        'priceType': priceType,
        if (priceType == 'fixed') 'price': price,
        if (priceType == 'range') ...{
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        },
        'durationMinutes': durationMinutes,
      };
      final url = ApiConstants.onboardingServiceById(serviceId);
      final options = await _authHeader;
      final response = await _dio.put(url, data: payload, options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update service',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    try {
      final url = ApiConstants.onboardingServiceById(serviceId);
      final options = await _authHeader;
      final response = await _dio.delete(url, options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete service',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> setAvailability({
    required List<String> workingDays,
    required String startTime,
    required String endTime,
    required bool sameDayRequests,
  }) async {
    try {
      final payload = {
        'workingDays': workingDays,
        'startTime': startTime,
        'endTime': endTime,
        'sameDayRequests': sameDayRequests,
      };
      final options = await _authHeader;
      final response = await _dio.put(
        ApiConstants.onboardingAvailability,
        data: payload,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to set availability',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> uploadDocument(
    File file,
    String documentType,
  ) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path, filename: fileName),
        'documentType': documentType,
      });

      final options = await _authHeader;
      options.headers?['Content-Type'] = 'multipart/form-data';

      final response = await _dio.post(
        ApiConstants.onboardingDocuments,
        data: formData,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload document',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final url = ApiConstants.onboardingDocumentById(documentId);
      final options = await _authHeader;
      final response = await _dio.delete(url, options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete document',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> getReview() async {
    try {
      final options = await _authHeader;
      final response = await _dio.get(
        ApiConstants.onboardingReview,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get review');
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> submitApplication() async {
    try {
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.onboardingSubmit,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit application',
      );
    } catch (e, stack) {
      print(
        'DEBUG: [OnboardingService.submitApplication] Unknown error: $e\n$stack',
      );
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final options = await _authHeader;
      final response = await _dio.get(
        ApiConstants.vendorDashboard,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load dashboard',
      );
    } catch (e, stack) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
