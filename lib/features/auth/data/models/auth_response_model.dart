import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel user;
  final String token;

  AuthResponseModel({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: UserModel.fromJson(json['data']['user']),
      token: json['data']['token'] ?? '',
    );
  }
}
