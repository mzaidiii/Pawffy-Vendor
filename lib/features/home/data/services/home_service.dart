import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
import '../models/home_data_model.dart';

class HomeService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<HomeDataModel> getHomeData() async {
    try {
      final options = await _authHeader;
      final response = await _dio.get(
        ApiConstants.home,
        options: options,
      );

      if (response.data != null && response.data['success'] == true) {
        return HomeDataModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch home data');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final options = await _authHeader;
      final response = await _dio.patch(
        ApiConstants.status,
        data: {'isOnline': isOnline},
        options: options,
      );

      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update online status',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
