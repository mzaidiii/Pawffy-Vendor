import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawffy/features/auth/providers/current_user_provider.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';
import '../data/models/address_model.dart';
import '../data/services/address_service.dart';

final addressServiceProvider = Provider<AddressService>((ref) => AddressService());

final addressControllerProvider =
    AsyncNotifierProvider.autoDispose<AddressController, List<AddressModel>>(
  AddressController.new,
);

class AddressController extends AsyncNotifier<List<AddressModel>> {
  @override
  Future<List<AddressModel>> build() async {
    return await ref.read(addressServiceProvider).getAddresses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final list = await ref.read(addressServiceProvider).getAddresses();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addAddress({
    required String label,
    required String address,
    required String city,
    required String stateVal,
    String? pincode,
    bool isDefault = false,
  }) async {
    await ref.read(addressServiceProvider).createAddress(
          label: label,
          address: address,
          city: city,
          state: stateVal,
          pincode: pincode,
          isDefault: isDefault,
        );
    if (isDefault) {
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileControllerProvider);
    }
    await refresh();
  }

  Future<void> editAddress({
    required String id,
    required String label,
    required String address,
    required String city,
    required String stateVal,
    String? pincode,
  }) async {
    await ref.read(addressServiceProvider).updateAddress(
          id: id,
          label: label,
          address: address,
          city: city,
          state: stateVal,
          pincode: pincode,
        );
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileControllerProvider);
    await refresh();
  }

  Future<void> setDefault(String id) async {
    await ref.read(addressServiceProvider).setDefaultAddress(id);
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileControllerProvider);
    await refresh();
  }

  Future<void> deleteAddress(String id) async {
    await ref.read(addressServiceProvider).deleteAddress(id);
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileControllerProvider);
    await refresh();
  }
}
