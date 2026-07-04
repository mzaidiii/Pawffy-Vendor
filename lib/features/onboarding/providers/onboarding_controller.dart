import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_provider.dart';

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, Map<String, dynamic>?>(
  OnboardingController.new,
);

class OnboardingController extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    // Return null initially, or fetch if user is logged in
    return null;
  }

  Future<void> fetchState() async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.fetchState] Fetching state from service');
      final data = await ref.read(onboardingServiceProvider).getOnboardingState();
      
      // Parse the response robustly
      final success = data['success'] as bool? ?? false;
      if (success && data['data'] != null) {
        state = AsyncData(data['data'] as Map<String, dynamic>);
        print('DEBUG: [OnboardingController.fetchState] Fetch success. State loaded.');
      } else {
        final msg = data['message'] as String? ?? 'Failed to load onboarding progress';
        print('DEBUG: [OnboardingController.fetchState] Fetch failed: $msg');
        state = AsyncError(Exception(msg), StackTrace.current);
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.fetchState] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
    }
  }

  Future<bool> saveBusinessInfo({
    required String businessName,
    required String contactName,
    required String phone,
    required String location,
    required String description,
  }) async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.saveBusinessInfo] Saving business info');
      final response = await ref.read(onboardingServiceProvider).saveBusinessInfo(
            businessName: businessName,
            contactName: contactName,
            phone: phone,
            location: location,
            description: description,
          );

      final success = response['success'] as bool? ?? false;
      if (success) {
        // Refresh state
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to save business info';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.saveBusinessInfo] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> addService({
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
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.addService] Adding service: $name');
      final response = await ref.read(onboardingServiceProvider).addService(
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

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to add service';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.addService] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.deleteService] Deleting service ID: $serviceId');
      final response = await ref.read(onboardingServiceProvider).deleteService(serviceId);

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to delete service';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.deleteService] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> saveAvailability({
    required List<String> workingDays,
    required String startTime,
    required String endTime,
    required bool sameDayRequests,
  }) async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.saveAvailability] Saving availability settings');
      final response = await ref.read(onboardingServiceProvider).setAvailability(
            workingDays: workingDays,
            startTime: startTime,
            endTime: endTime,
            sameDayRequests: sameDayRequests,
          );

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to save availability';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.saveAvailability] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> uploadDocument(File file, String documentType) async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.uploadDocument] Uploading document: $documentType');
      final response = await ref.read(onboardingServiceProvider).uploadDocument(file, documentType);

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to upload document';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.uploadDocument] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.deleteDocument] Deleting document ID: $documentId');
      final response = await ref.read(onboardingServiceProvider).deleteDocument(documentId);

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to delete document';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.deleteDocument] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> submitApplication() async {
    state = const AsyncLoading();
    try {
      print('DEBUG: [OnboardingController.submitApplication] Submitting application for review');
      final response = await ref.read(onboardingServiceProvider).submitApplication();

      final success = response['success'] as bool? ?? false;
      if (success) {
        await fetchState();
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Failed to submit application';
        state = AsyncError(Exception(msg), StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingController.submitApplication] Error caught: $e\n$stack');
      state = AsyncError(e, stack);
      return false;
    }
  }
}
