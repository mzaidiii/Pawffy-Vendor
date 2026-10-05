import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/current_user_provider.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';
import 'package:pawffy/features/profile/data/models/address_model.dart';
import 'package:pawffy/features/profile/providers/address_controller.dart';

class ManageAddressesScreen extends ConsumerStatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  ConsumerState<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends ConsumerState<ManageAddressesScreen> {
  bool _isActionLoading = false;

  void _showAddEditBottomSheet({AddressModel? existingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressFormSheet(
        existingAddress: existingAddress,
        onSave: (label, address, city, stateVal, pincode, isDefault) async {
          Navigator.pop(ctx);
          setState(() => _isActionLoading = true);
          try {
            if (existingAddress == null) {
              await ref.read(addressControllerProvider.notifier).addAddress(
                    label: label,
                    address: address,
                    city: city,
                    stateVal: stateVal,
                    pincode: pincode,
                    isDefault: isDefault,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address added successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              await ref.read(addressControllerProvider.notifier).editAddress(
                    id: existingAddress.id,
                    label: label,
                    address: address,
                    city: city,
                    stateVal: stateVal,
                    pincode: pincode,
                  );
              if (isDefault && !existingAddress.isDefault) {
                await ref.read(addressControllerProvider.notifier).setDefault(existingAddress.id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _isActionLoading = false);
          }
        },
      ),
    );
  }

  Future<void> _handleSetDefault(AddressModel addr) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(addressControllerProvider.notifier).setDefault(addr.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${addr.label} address set as default'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDelete(AddressModel addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Address',
            style: GoogleFonts.barlow(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this address?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppColors.white.withOpacity(0.8) : AppColors.black.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'DELETE',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isActionLoading = true);
      try {
        await ref.read(addressControllerProvider.notifier).deleteAddress(addr.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressesAsync = ref.watch(addressControllerProvider);

    // Dynamic styles
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final subtextColor = isDark ? AppColors.white.withOpacity(0.7) : AppColors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SAVED ADDRESSES',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.orange, size: 24),
            tooltip: 'Add Address',
            onPressed: () => _showAddEditBottomSheet(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => ref.read(addressControllerProvider.notifier).refresh(),
              child: addressesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
                error: (err, st) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load addresses',
                              style: GoogleFonts.barlow(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err.toString().replaceAll('Exception: ', ''),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => ref.read(addressControllerProvider.notifier).refresh(),
                              child: Text(
                                'RETRY',
                                style: GoogleFonts.barlow(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                data: (addresses) {
                  // Sort addresses so that default address is always at top
                  final sortedList = List<AddressModel>.from(addresses)
                    ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));

                  if (sortedList.isEmpty) {
                    return _buildEmptyState(context, isDark, cardColor, borderColor, textColor, subtextColor);
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: sortedList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = sortedList[index];
                      return _buildAddressCard(
                        item: item,
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      );
                    },
                  );
                },
              ),
            ),
            if (_isActionLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: AppColors.orange.withOpacity(0.35),
            ),
            onPressed: () => _showAddEditBottomSheet(),
            icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.white, size: 20),
            label: Text(
              'ADD NEW ADDRESS',
              style: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    // Check if user info API provides an initial address
    final user = ref.watch(currentUserProvider).asData?.value;
    final profile = ref.watch(profileControllerProvider).asData?.value;

    final fallbackAddress = profile?.profile.location ?? user?.address;
    final fallbackCity = profile?.profile.city ?? user?.city;
    final fallbackState = profile?.profile.state ?? user?.state;

    final hasUserProfileAddress = (fallbackAddress != null && fallbackAddress.isNotEmpty) ||
        (fallbackCity != null && fallbackCity.isNotEmpty);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasUserProfileAddress) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Default address from your main profile',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PROFILE DEFAULT',
                          style: GoogleFonts.barlow(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.orange, size: 22),
                        tooltip: 'Save as address item',
                        onPressed: () {
                          _showAddEditBottomSheet(
                            existingAddress: AddressModel(
                              id: '',
                              label: 'Home',
                              address: fallbackAddress ?? '',
                              city: fallbackCity ?? '',
                              state: fallbackState ?? '',
                              pincode: '',
                              isDefault: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fallbackAddress ?? 'No street address specified',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (fallbackCity != null || fallbackState != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        '${fallbackCity ?? ''}${fallbackCity != null && fallbackState != null ? ', ' : ''}${fallbackState ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(height: hasUserProfileAddress ? 12 : 80),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: isDark ? AppColors.grey : AppColors.greyLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Saved Addresses Yet',
                  style: GoogleFonts.barlow(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add custom addresses for quick selection during service management.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required AddressModel item,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isDefault ? AppColors.orange : borderColor,
          width: item.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.label.toUpperCase(),
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (item.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'DEFAULT',
                              style: GoogleFonts.barlow(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: subtextColor, size: 20),
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'default') {
                      _handleSetDefault(item);
                    } else if (val == 'edit') {
                      _showAddEditBottomSheet(existingAddress: item);
                    } else if (val == 'delete') {
                      _handleDelete(item);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!item.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            const Icon(Icons.star_outline_rounded, color: AppColors.orange, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Set as Default',
                              style: GoogleFonts.inter(fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, color: AppColors.grey, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Edit Address',
                            style: GoogleFonts.inter(fontSize: 13, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: item.isDefault ? AppColors.orange : subtextColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.address,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.city}${item.city.isNotEmpty && item.state.isNotEmpty ? ', ' : ''}${item.state}${item.pincode.isNotEmpty ? ' - ${item.pincode}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final AddressModel? existingAddress;
  final Function(String label, String address, String city, String state, String pincode, bool isDefault) onSave;

  const _AddressFormSheet({
    this.existingAddress,
    required this.onSave,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _customLabelCtrl;

  String _selectedLabel = 'Home';
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _addressCtrl = TextEditingController(text: addr?.address ?? '');
    _cityCtrl = TextEditingController(text: addr?.city ?? '');
    _stateCtrl = TextEditingController(text: addr?.state ?? '');
    _pincodeCtrl = TextEditingController(text: addr?.pincode ?? '');
    _customLabelCtrl = TextEditingController();

    if (addr != null) {
      if (['Home', 'Work', 'Clinic'].contains(addr.label)) {
        _selectedLabel = addr.label;
      } else {
        _selectedLabel = 'Other';
        _customLabelCtrl.text = addr.label;
      }
      _isDefault = addr.isDefault;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _customLabelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final finalLabel = _selectedLabel == 'Other'
          ? (_customLabelCtrl.text.trim().isEmpty ? 'Other' : _customLabelCtrl.text.trim())
          : _selectedLabel;

      widget.onSave(
        finalLabel,
        _addressCtrl.text.trim(),
        _cityCtrl.text.trim(),
        _stateCtrl.text.trim(),
        _pincodeCtrl.text.trim(),
        _isDefault,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final inputBg = isDark ? AppColors.darkBg : Colors.grey.shade100;
    final isEditing = widget.existingAddress != null && widget.existingAddress!.id.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header drag line
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'EDIT ADDRESS' : 'ADD NEW ADDRESS',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Label selector chips
                Text(
                  'Address Type / Label',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Home', 'Work', 'Clinic', 'Other'].map((lbl) {
                    final isSelected = _selectedLabel == lbl;
                    return ChoiceChip(
                      label: Text(
                        lbl,
                        style: GoogleFonts.barlow(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.white
                              : (isDark ? AppColors.white : AppColors.black),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.orange,
                      backgroundColor: inputBg,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedLabel = lbl);
                      },
                    );
                  }).toList(),
                ),
                if (_selectedLabel == 'Other') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customLabelCtrl,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter custom label (e.g. Parents House)',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Address field
                Text(
                  'Street Address',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 14, color: textColor),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Street address is required' : null,
                  decoration: InputDecoration(
                    hintText: 'House/Flat No., Building Name, Street',
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // City & State Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City',
                            style: GoogleFonts.barlow(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _cityCtrl,
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'City required' : null,
                            decoration: InputDecoration(
                              hintText: 'City',
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'State',
                            style: GoogleFonts.barlow(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stateCtrl,
                            style: GoogleFonts.inter(fontSize: 14, color: textColor),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'State required' : null,
                            decoration: InputDecoration(
                              hintText: 'State',
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pincode
                Text(
                  'Pin Code (Postal Code)',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pincodeCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. 400053',
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Default switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.orange,
                  title: Text(
                    'Set as Default Address',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'This primary address will be synced with your profile',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey),
                  ),
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                ),
                const SizedBox(height: 16),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditing ? 'SAVE CHANGES' : 'ADD ADDRESS',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
