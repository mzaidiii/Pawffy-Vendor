import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawffy/core/Storage/storage_service.dart';
import 'auth_provider.dart';
import 'package:pawffy/features/auth/data/models/user_model.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final authService = ref.read(authServiceProvider);

      final response = await authService.login(
        email: email,
        password: password,
      );

      await StorageService.saveToken(response.token);
      await StorageService.saveUserId(response.user.id);

      state = const AsyncData(null);

      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<UserModel?> getMe() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) return null;

      final authService = ref.read(authServiceProvider);

      return await authService.getMe(token);
    } catch (_) {
      return null;
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final msg = await authService.forgotPassword(email: email);
      state = const AsyncData(null);
      return msg;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}
