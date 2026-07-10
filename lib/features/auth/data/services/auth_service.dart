import 'package:dio/dio.dart';

import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import '../models/auth_response_model.dart';
import 'package:pawffy/features/auth/data/models/user_model.dart';

class AuthService {
  final Dio _dio = DioClient.dio;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    try {
      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'acceptTerms': acceptTerms,
      };

      final response = await _dio.post(ApiConstants.register, data: payload);

      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getMe(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data['data']['token'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to change password',
      );
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      return response.data['message'] as String? ??
          'Password reset link sent to your email';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Forgot password failed');
    }
  }

  Future<void> logout(String token) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Logout failed');
    }
  }

  Future<void> requestEmailChange({
    required String newEmail,
    required String password,
    required String token,
  }) async {
    try {
      await _dio.post(
        ApiConstants.requestEmailChange,
        data: {'newEmail': newEmail, 'password': password},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to request email change',
      );
    }
  }

  Future<String> verifyEmailChange({
    required String newEmail,
    required String verificationToken,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyEmailChange,
        data: {'newEmail': newEmail, 'token': verificationToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['data']['token'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Email verification failed',
      );
    }
  }

  Future<void> requestPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    try {
      await _dio.post(
        ApiConstants.requestPhoneChange,
        data: {'newPhone': newPhone},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to request phone change',
      );
    }
  }

  Future<String> verifyPhoneChange({
    required String newPhone,
    required String otp,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyPhoneChange,
        data: {'newPhone': newPhone, 'otp': otp},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['data']['token'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Phone verification failed',
      );
    }
  }
}
