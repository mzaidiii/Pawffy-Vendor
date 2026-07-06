import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
import '../models/calendar_day_model.dart';
import '../models/blocked_date_model.dart';

class CalendarService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<CalendarDayModel> getCalendarDay({String? date}) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendar,
        queryParameters: date != null ? {'date': date} : null,
        options: await _authHeader,
      );
      if (response.data != null && response.data['success'] == true) {
        return CalendarDayModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch calendar day');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<List<BlockedDateModel>> getBlockedDates() async {
    try {
      final response = await _dio.get(
        ApiConstants.blockedDates,
        options: await _authHeader,
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.map((json) => BlockedDateModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch blocked dates');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch blocked dates',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<BlockedDateModel> addBlockedDate(String date, String reason) async {
    try {
      final response = await _dio.post(
        ApiConstants.blockedDates,
        data: {'date': date, 'reason': reason},
        options: await _authHeader,
      );
      if (response.data != null && response.data['success'] == true) {
        return BlockedDateModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add blocked date');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add blocked date',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> removeBlockedDate(String id) async {
    try {
      final response = await _dio.delete(
        ApiConstants.deleteBlockedDate(id),
        options: await _authHeader,
      );
      if (response.data == null || response.data['success'] != true) {
        throw Exception(response.data?['message'] ?? 'Failed to delete blocked date');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete blocked date',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
