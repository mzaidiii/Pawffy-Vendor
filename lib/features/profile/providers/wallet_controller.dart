import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, WalletModel>(
  WalletController.new,
);

class WalletController extends AsyncNotifier<WalletModel> {
  late final WalletService _service;

  @override
  Future<WalletModel> build() async {
    _service = ref.read(walletServiceProvider);
    return await _service.getWallet();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getWallet());
  }

  Future<bool> withdraw(double amount) async {
    try {
      final success = await _service.withdrawFunds(amount);
      if (success) {
        await refresh();
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
