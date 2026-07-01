import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import 'notification_provider.dart';

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<NotificationModel>>(
      () => NotificationController(),
    );

final unreadCountProvider = Provider<int>((ref) {
  final notifAsync = ref.watch(notificationControllerProvider);
  return notifAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationController extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return await _fetch();
  }

  Future<List<NotificationModel>> _fetch() async {
    final service = ref.read(notificationServiceProvider);
    return await service.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetch());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> markAsRead(String notifId) async {
    final service = ref.read(notificationServiceProvider);
    try {
      await service.markAsRead(notifId);
      state = AsyncData(
        state.value!.map((n) {
          return n.id == notifId ? n.copyWith(isRead: true) : n;
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final service = ref.read(notificationServiceProvider);
    try {
      await service.markAllRead();
      state = AsyncData(
        state.value!.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteNotification(String notifId) async {
    final service = ref.read(notificationServiceProvider);
    try {
      await service.deleteNotification(notifId);
      state = AsyncData(state.value!.where((n) => n.id != notifId).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
