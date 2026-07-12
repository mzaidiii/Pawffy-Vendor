import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';

class WalletTransactionModel {
  final String id;
  final double amount;
  final String type;
  final String description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '') ?? 0.0),
      type: json['type']?.toString() ?? 'credit',
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletModel {
  final double balance;
  final List<WalletTransactionModel> transactions;

  WalletModel({
    required this.balance,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final balanceVal = json['balance'] is num
        ? (json['balance'] as num).toDouble()
        : (double.tryParse(json['balance']?.toString() ?? '') ?? 0.0);
    final txList = json['transactions'] as List? ?? [];
    return WalletModel(
      balance: balanceVal,
      transactions: txList
          .map((tx) => WalletTransactionModel.fromJson(tx))
          .toList(),
    );
  }
}

class WalletService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<WalletModel> getWallet() async {
    try {
      final response = await _dio.get(
        ApiConstants.wallet,
        queryParameters: {'limit': 20},
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        return WalletModel.fromJson(body['data']);
      }
      throw Exception(body?['message'] ?? 'Failed to parse wallet response');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to connect to wallet backend',
      );
    }
  }

  Future<bool> withdrawFunds(double amount) async {
    try {
      final response = await _dio.post(
        ApiConstants.withdraw,
        data: {'amount': amount},
        options: await _authHeader,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to request withdrawal',
      );
    }
  }
}
