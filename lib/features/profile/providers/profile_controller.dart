import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawffy/features/auth/providers/current{_user_provider.dart';
import '../data/models/vendor_profile_model.dart';
import '../data/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

class ProfilePeriodNotifier extends Notifier<String> {
  @override
  String build() => 'month';

  void setPeriod(String period) {
    state = period;
  }
}

final profilePeriodProvider = NotifierProvider.autoDispose<ProfilePeriodNotifier, String>(
  ProfilePeriodNotifier.new,
);

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, VendorProfileModel>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<VendorProfileModel> {
  @override
  Future<VendorProfileModel> build() async {
    final period = ref.watch(profilePeriodProvider);
    return await ref.read(profileServiceProvider).getProfile(period: period);
  }

  Future<void> changePeriod(String period) async {
    ref.read(profilePeriodProvider.notifier).setPeriod(period);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final period = ref.read(profilePeriodProvider);
      final profile = await ref.read(profileServiceProvider).getProfile(period: period);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateProfile({
    required String contactName,
    required String businessName,
    required String phone,
    required String location,
    required String city,
    required String state,
    required String profileTitle,
    required String description,
    String? dob,
    String? gender,
    String? pinCode,
  }) async {
    await ref.read(profileServiceProvider).updateProfile(
      contactName: contactName,
      businessName: businessName,
      phone: phone,
      location: location,
      city: city,
      state: state,
      profileTitle: profileTitle,
      description: description,
      dob: dob,
      gender: gender,
      pinCode: pinCode,
    );
    ref.invalidateSelf();
    ref.invalidate(currentUserProvider);
  }

  Future<void> uploadAvatar(String filePath) async {
    await ref.read(profileServiceProvider).uploadAvatar(filePath);
    ref.invalidateSelf();
    ref.invalidate(currentUserProvider);
  }
}

class NotificationPreferencesNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return await ref.read(profileServiceProvider).getNotificationPreferences();
  }

  Future<void> updatePreferences({
    required bool pushRequests,
    required bool pushMessages,
    required bool emailMarketing,
    required bool smsAlerts,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileServiceProvider).updateNotificationPreferences(
        pushRequests: pushRequests,
        pushMessages: pushMessages,
        emailMarketing: emailMarketing,
        smsAlerts: smsAlerts,
      );
      state = AsyncData({
        'pushRequests': pushRequests,
        'pushMessages': pushMessages,
        'emailMarketing': emailMarketing,
        'smsAlerts': smsAlerts,
      });
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider.autoDispose<NotificationPreferencesNotifier, Map<String, dynamic>>(
  NotificationPreferencesNotifier.new,
);

final servicesControllerProvider =
    AsyncNotifierProvider.autoDispose<ServicesController, List<VendorServiceModel>>(
  ServicesController.new,
);

class ServicesController extends AsyncNotifier<List<VendorServiceModel>> {
  @override
  Future<List<VendorServiceModel>> build() async {
    return await ref.read(profileServiceProvider).getServices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final services = await ref.read(profileServiceProvider).getServices();
      state = AsyncData(services);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addService({
    required String serviceType,
    required String name,
    required String description,
    required List<String> inclusions,
    required int durationMinutes,
    required String priceType,
    double? price,
    double? minPrice,
    double? maxPrice,
    required String serviceLocation,
  }) async {
    await ref.read(profileServiceProvider).addService(
      serviceType: serviceType,
      name: name,
      description: description,
      inclusions: inclusions,
      durationMinutes: durationMinutes,
      priceType: priceType,
      price: price,
      minPrice: minPrice,
      maxPrice: maxPrice,
      serviceLocation: serviceLocation,
    );
    ref.invalidate(profileControllerProvider);
    ref.invalidateSelf();
  }

  Future<void> updateService({
    required String serviceId,
    required String serviceType,
    required String name,
    required String description,
    required List<String> inclusions,
    required int durationMinutes,
    required String priceType,
    double? price,
    double? minPrice,
    double? maxPrice,
    required String serviceLocation,
  }) async {
    await ref.read(profileServiceProvider).updateService(
      serviceId: serviceId,
      serviceType: serviceType,
      name: name,
      description: description,
      inclusions: inclusions,
      durationMinutes: durationMinutes,
      priceType: priceType,
      price: price,
      minPrice: minPrice,
      maxPrice: maxPrice,
      serviceLocation: serviceLocation,
    );
    ref.invalidate(profileControllerProvider);
    ref.invalidateSelf();
  }

  Future<void> deleteService(String serviceId) async {
    await ref.read(profileServiceProvider).deleteService(serviceId);
    ref.invalidate(profileControllerProvider);
    ref.invalidateSelf();
  }
}
