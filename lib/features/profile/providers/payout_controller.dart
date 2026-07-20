import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/payout_service.dart';

final payoutServiceProvider = Provider<PayoutService>((ref) => PayoutService());

class StripePayoutState {
  final bool onboarded;
  final bool payoutsEnabled;
  final String? stripeAccountId;

  StripePayoutState({
    required this.onboarded,
    required this.payoutsEnabled,
    this.stripeAccountId,
  });

  factory StripePayoutState.fromJson(Map<String, dynamic> json) {
    return StripePayoutState(
      onboarded: json['onboarded'] as bool? ?? false,
      payoutsEnabled: json['payoutsEnabled'] as bool? ?? false,
      stripeAccountId: json['stripeAccountId']?.toString(),
    );
  }
}

final payoutControllerProvider =
    AsyncNotifierProvider<PayoutController, StripePayoutState>(
  PayoutController.new,
);

class PayoutController extends AsyncNotifier<StripePayoutState> {
  late final PayoutService _service;

  @override
  Future<StripePayoutState> build() async {
    _service = ref.read(payoutServiceProvider);
    final data = await _service.checkPayoutStatus();
    return StripePayoutState.fromJson(data);
  }

  Future<void> refreshStatus() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await _service.checkPayoutStatus();
      return StripePayoutState.fromJson(data);
    });
  }

  Future<String?> linkStripeAccount() async {
    try {
      final data = await _service.startOnboarding();
      return data['url']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyAndSyncStatus() async {
    try {
      final data = await _service.syncPayoutStatus();
      final updatedState = StripePayoutState.fromJson(data);
      state = AsyncData(updatedState);
      return updatedState.onboarded;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
