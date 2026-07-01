import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawffy/features/auth/data/models/user_model.dart';
import 'package:pawffy/features/auth/providers/auth_controller.dart';

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
      CurrentUserNotifier.new,
    );

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return await ref.read(authControllerProvider.notifier).getMe();
  }

  void clear() {
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authControllerProvider.notifier).getMe();
    });
  }
}
