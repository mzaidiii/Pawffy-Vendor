import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/current{_user_provider.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends ConsumerState<PersonalInformationScreen> {
  final _fullNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCodeCtrl = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Populate with existing data
    final profile = ref.read(profileControllerProvider).asData?.value;
    if (profile != null) {
      _fullNameCtrl.text = profile.profile.name;
      _addressCtrl.text = profile.profile.location ?? '';
      _cityCtrl.text = profile.profile.city ?? '';
      _stateCtrl.text = profile.profile.state ?? '';
    } else {
      final user = ref.read(currentUserProvider).asData?.value;
      if (user != null) {
        _fullNameCtrl.text = user.name;
        _addressCtrl.text = user.address ?? '';
        _cityCtrl.text = user.city ?? '';
        _stateCtrl.text = user.state ?? '';
      }
    }
    _dobCtrl.text = '12 May 1995'; // Placeholder
    _pinCodeCtrl.text = '546014';  // Placeholder
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.white : AppColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PERSONAL INFORMATION',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.white : AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar display
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                              border: Border.all(color: AppColors.orange, width: 2),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.grey, size: 40),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    _buildLabel('Full Name'),
                    TextField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                    ),
                    const SizedBox(height: 14),

                    // Date of Birth
                    _buildLabel('Date of Birth'),
                    TextField(
                      controller: _dobCtrl,
                      readOnly: true,
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1995, 5, 12),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) {
                          setState(() {
                            _dobCtrl.text = '${selected.day} ${_getMonthName(selected.month)} ${selected.year}';
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Select Date of Birth',
                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gender Dropdown
                    _buildLabel('Gender'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGender = val);
                          },
                          items: ['Male', 'Female', 'Other'].map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _buildLabel('Address'),
                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(hintText: 'Enter address'),
                    ),
                    const SizedBox(height: 14),

                    // City
                    _buildLabel('City'),
                    TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(hintText: 'Enter city'),
                    ),
                    const SizedBox(height: 14),

                    // State
                    _buildLabel('State'),
                    TextField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(hintText: 'Enter state'),
                    ),
                    const SizedBox(height: 14),

                    // Pin Code
                    _buildLabel('Pin Code'),
                    TextField(
                      controller: _pinCodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Enter pin code'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final profile = ref.read(profileControllerProvider).asData?.value;
                            await ref.read(profileControllerProvider.notifier).updateProfile(
                                  contactName: _fullNameCtrl.text,
                                  businessName: profile?.profile.businessName ?? '',
                                  phone: profile?.profile.phone ?? '',
                                  location: _addressCtrl.text,
                                  city: _cityCtrl.text,
                                  state: _stateCtrl.text,
                                  profileTitle: profile?.profile.title ?? '',
                                  description: profile?.profile.description ?? '',
                                  dob: _dobCtrl.text,
                                  gender: _selectedGender,
                                  pinCode: _pinCodeCtrl.text,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Changes saved successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save changes: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('SAVE CHANGES'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
