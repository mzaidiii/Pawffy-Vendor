import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';
import '../models/address_model.dart';

class AddressService {
  final Dio _dio = DioClient.dio;

  Future<Options> _getOptions() async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<AddressModel>> getAddresses() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.userAddresses,
        options: options,
      );

      final body = response.data;
      List<dynamic> listData = [];
      if (body is List) {
        listData = body;
      } else if (body is Map) {
        if (body['data'] != null) {
          if (body['data'] is List) {
            listData = body['data'];
          } else if (body['data'] is Map && body['data']['addresses'] is List) {
            listData = body['data']['addresses'];
          }
        } else if (body['addresses'] is List) {
          listData = body['addresses'];
        }
      }

      return listData
          .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load addresses',
      );
    }
  }

  Future<AddressModel> createAddress({
    required String label,
    required String address,
    required String city,
    required String state,
    String? pincode,
    bool isDefault = false,
  }) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        ApiConstants.userAddresses,
        data: {
          'label': label,
          'address': address,
          'city': city,
          'state': state,
          if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
          'isDefault': isDefault,
        },
        options: options,
      );

      final body = response.data;
      final data = (body is Map && body['data'] != null) ? body['data'] : body;
      return AddressModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create address',
      );
    }
  }

  Future<AddressModel> updateAddress({
    required String id,
    required String label,
    required String address,
    required String city,
    required String state,
    String? pincode,
  }) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        ApiConstants.userAddressById(id),
        data: {
          'label': label,
          'address': address,
          'city': city,
          'state': state,
          if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        },
        options: options,
      );

      final body = response.data;
      final data = (body is Map && body['data'] != null) ? body['data'] : body;
      return AddressModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update address',
      );
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final options = await _getOptions();
      await _dio.patch(
        ApiConstants.setUserAddressDefault(id),
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to set default address',
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      final options = await _getOptions();
      await _dio.delete(
        ApiConstants.userAddressById(id),
        options: options,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete address',
      );
    }
  }
}
