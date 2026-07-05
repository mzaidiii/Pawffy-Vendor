import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/home_data_model.dart';
import 'home_provider.dart';

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeDataModel?>(
  HomeController.new,
);

class HomeController extends AsyncNotifier<HomeDataModel?> {
  @override
  Future<HomeDataModel?> build() async {
    return await _fetch();
  }

  Future<HomeDataModel?> _fetch() async {
    try {
      final service = ref.read(homeServiceProvider);
      return await service.getHomeData();
    } catch (e) {
      // Return null or rethrow based on preference.
      // Rethrowing is good so the UI can catch and display errors.
      rethrow;
    }
  }

  Future<void> fetchHomeData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _fetch();
    });
  }

  Future<void> refresh() async {
    // Keep current data while loading if desired, or set loading.
    // AsyncValue.guard keeps the interface responsive.
    state = await AsyncValue.guard(() async {
      return await _fetch();
    });
  }

  Future<bool> toggleOnlineStatus() async {
    final currentData = state.value;
    if (currentData == null) return false;

    final newStatus = !currentData.header.isOnline;
    
    // Optimistic UI update:
    // We update the local state immediately for a fast, premium response.
    final updatedHeader = HomeHeader(
      name: currentData.header.name,
      businessName: currentData.header.businessName,
      location: currentData.header.location,
      city: currentData.header.city,
      state: currentData.header.state,
      profileImage: currentData.header.profileImage,
      isOnline: newStatus,
      unreadNotifications: currentData.header.unreadNotifications,
    );

    final updatedData = HomeDataModel(
      header: updatedHeader,
      applicationStatus: currentData.applicationStatus,
      banner: currentData.banner,
      todayAtAGlance: currentData.todayAtAGlance,
      upcomingBookings: currentData.upcomingBookings,
      requestsAvailable: currentData.requestsAvailable,
    );

    state = AsyncData(updatedData);

    try {
      final service = ref.read(homeServiceProvider);
      final success = await service.updateOnlineStatus(newStatus);
      if (!success) {
        // Revert if API call fails
        state = AsyncData(currentData);
        return false;
      }
      return true;
    } catch (_) {
      // Revert if API call throws
      state = AsyncData(currentData);
      return false;
    }
  }
}
