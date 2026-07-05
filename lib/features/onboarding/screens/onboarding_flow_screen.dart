import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawffy/features/onboarding/providers/onboarding_controller.dart';
import 'package:pawffy/features/home/home_screen.dart';
import 'package:pawffy/core/utils/image_picker_helper.dart';
import 'package:pawffy/features/auth/providers/auth_controller.dart';
import 'package:pawffy/features/auth/Login_Screen.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
import 'package:pawffy/features/onboarding/providers/onboarding_provider.dart';

enum OnboardingStep {
  businessInfo,
  configureServices,
  serviceDetails,
  availability,
  verifyBusiness,
  reviewBusiness,
  verificationPending,
}

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  OnboardingStep _currentStep = OnboardingStep.businessInfo;

  // Business info form controllers
  final _businessNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Service details form controllers
  String _selectedServiceType = 'groomer';
  final _serviceNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  String _selectedPriceType = 'fixed';
  final _priceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String _selectedServiceLocation = 'at_my_place';
  final _inclusionController = TextEditingController();
  final List<String> _inclusionsList = [];
  String? _editingServiceId; // If editing a service

  // Availability form states
  final List<String> _workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final _startTimeController = TextEditingController(text: '09:00 AM');
  final _endTimeController = TextEditingController(text: '06:00 PM');
  bool _sameDayRequests = true;

  // Selected document image file
  File? _selectedLicenseFile;
  bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    // Load onboarding data from API on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnboardingState();
    });
  }

  Future<void> _loadOnboardingState() async {
    await ref.read(onboardingControllerProvider.notifier).fetchState();
    final stateData = ref.read(onboardingControllerProvider).value;
    if (stateData != null) {
      _populateFromState(stateData);
    }
  }

  void _populateFromState(Map<String, dynamic> data) {
    try {
      print(
        'DEBUG: [OnboardingFlowScreen._populateFromState] Populate data: $data',
      );

      // 1. Business Info
      if (data['business'] != null) {
        final b = data['business'] as Map<String, dynamic>;
        _businessNameController.text = b['businessName']?.toString() ?? '';
        _contactNameController.text = b['contactName']?.toString() ?? '';
        _phoneController.text = b['phone']?.toString() ?? '';
        _locationController.text = b['location']?.toString() ?? '';
        _descriptionController.text = b['description']?.toString() ?? '';

        final status = b['verificationStatus']?.toString() ?? 'draft';
        if (status == 'pending') {
          setState(() {
            _currentStep = OnboardingStep.verificationPending;
          });
        }
      }

      // 2. Availability
      if (data['availability'] != null) {
        final av = data['availability'] as Map<String, dynamic>;
        if (av['workingDays'] != null) {
          _workingDays.clear();
          _workingDays.addAll(List<String>.from(av['workingDays']));
        }
        _startTimeController.text = av['startTime']?.toString() ?? '09:00 AM';
        _endTimeController.text = av['endTime']?.toString() ?? '06:00 PM';
        _sameDayRequests = av['sameDayRequests'] as bool? ?? true;
      }
    } catch (e, stack) {
      print(
        'DEBUG: [OnboardingFlowScreen._populateFromState] Error populating fields: $e\n$stack',
      );
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _serviceNameController.dispose();
    _serviceDescController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _inclusionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // Pick time picker
  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE85D04),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
          final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
          final minute = picked.minute.toString().padLeft(2, '0');
          final hourStr = hour.toString().padLeft(2, '0');
          controller.text = '$hourStr:$minute $period';
        });
      }
    }
  }

  // Upload license file
  Future<void> _pickAndUploadLicense() async {
    try {
      final file = await ImagePickerHelper.pickImageWithPermission(
        context: context,
        source: ImageSource.gallery,
      );

      if (file == null) {
        print('DEBUG: [OnboardingFlowScreen] No file selected');
        return;
      }

      setState(() {
        _selectedLicenseFile = File(file.path);
        _isUploadingDocument = true;
      });

      print(
        'DEBUG: [OnboardingFlowScreen] Selected file path: ${file.path}. Starting upload...',
      );
      final success = await ref
          .read(onboardingControllerProvider.notifier)
          .uploadDocument(_selectedLicenseFile!, 'business_license');

      if (mounted) {
        setState(() {
          _isUploadingDocument = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Document uploaded successfully!',
                style: GoogleFonts.barlow(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _selectedLicenseFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload document.',
                style: GoogleFonts.barlow(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e, stack) {
      print(
        'DEBUG: [OnboardingFlowScreen] Upload failed with error: $e\n$stack',
      );
      if (mounted) {
        setState(() {
          _isUploadingDocument = false;
          _selectedLicenseFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.barlow()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Navigation Logic
  void _goToNextStep() {
    setState(() {
      switch (_currentStep) {
        case OnboardingStep.businessInfo:
          _currentStep = OnboardingStep.configureServices;
          break;
        case OnboardingStep.configureServices:
          _currentStep = OnboardingStep.availability;
          break;
        case OnboardingStep.availability:
          _currentStep = OnboardingStep.verifyBusiness;
          break;
        case OnboardingStep.verifyBusiness:
          _currentStep = OnboardingStep.reviewBusiness;
          break;
        case OnboardingStep.reviewBusiness:
          _currentStep = OnboardingStep.verificationPending;
          break;
        default:
          break;
      }
    });
  }

  void _goToPrevStep() {
    setState(() {
      switch (_currentStep) {
        case OnboardingStep.configureServices:
          _currentStep = OnboardingStep.businessInfo;
          break;
        case OnboardingStep.serviceDetails:
          _currentStep = OnboardingStep.configureServices;
          break;
        case OnboardingStep.availability:
          _currentStep = OnboardingStep.configureServices;
          break;
        case OnboardingStep.verifyBusiness:
          _currentStep = OnboardingStep.availability;
          break;
        case OnboardingStep.reviewBusiness:
          _currentStep = OnboardingStep.verifyBusiness;
          break;
        default:
          break;
      }
    });
  }

  // Handle saving Business Info
  Future<void> _saveBusinessInfo() async {
    final businessName = _businessNameController.text.trim();
    final contactName = _contactNameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();

    if (businessName.isEmpty ||
        contactName.isEmpty ||
        phone.isEmpty ||
        location.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .saveBusinessInfo(
          businessName: businessName,
          contactName: contactName,
          phone: phone,
          location: location,
          description: description,
        );

    if (success && mounted) {
      _goToNextStep();
    }
  }

  // Handle saving Service details
  Future<void> _saveService() async {
    final name = _serviceNameController.text.trim();
    final desc = _serviceDescController.text.trim();
    final duration = int.tryParse(_durationController.text) ?? 60;
    final price = double.tryParse(_priceController.text);
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);

    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter service name and description',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedPriceType == 'fixed' && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid price',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedPriceType == 'range' &&
        (minPrice == null || maxPrice == null || minPrice >= maxPrice)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid price range',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = false;
    if (_editingServiceId == null) {
      // Add Service
      success = await ref
          .read(onboardingControllerProvider.notifier)
          .addService(
            serviceType: _selectedServiceType,
            name: name,
            description: desc,
            inclusions: _inclusionsList,
            durationMinutes: duration,
            priceType: _selectedPriceType,
            price: price,
            minPrice: minPrice,
            maxPrice: maxPrice,
            serviceLocation: _selectedServiceLocation,
          );
    } else {
      // Update service endpoint
      final onboardingService = ref.read(onboardingServiceProvider);
      try {
        final res = await onboardingService.updateService(
          serviceId: _editingServiceId!,
          name: name,
          priceType: _selectedPriceType,
          price: price,
          minPrice: minPrice,
          maxPrice: maxPrice,
          durationMinutes: duration,
        );
        success = res['success'] as bool? ?? false;
        if (success) {
          await ref.read(onboardingControllerProvider.notifier).fetchState();
        }
      } catch (e) {
        print('DEBUG: [OnboardingFlowScreen.updateService] Error: $e');
      }
    }

    if (success && mounted) {
      setState(() {
        _editingServiceId = null;
        _currentStep = OnboardingStep.configureServices;
      });
    }
  }

  // Save availability details
  Future<void> _saveAvailability() async {
    if (_workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one working day',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .saveAvailability(
          workingDays: _workingDays,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          sameDayRequests: _sameDayRequests,
        );

    if (success && mounted) {
      _goToNextStep();
    }
  }

  // Submit Application
  Future<void> _submitApplication() async {
    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .submitApplication();
    if (success && mounted) {
      _goToNextStep();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit application. Please review details.',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .forgotPassword(email: ''); // just placeholder or force clear
      } catch (_) {}
    }
    await StorageService.clearAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE85D04)),
          ),
          error: (err, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${err.toString().replaceFirst('Exception: ', '')}',
                    style: GoogleFonts.barlow(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadOnboardingState,
                    child: Text('Retry', style: GoogleFonts.barlow()),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _handleLogout,
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.barlow(color: const Color(0xFFE85D04)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final parsedData = data ?? {};
            return Column(
              children: [
                if (_currentStep != OnboardingStep.verificationPending)
                  _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: _buildStepBody(parsedData),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String fullTitle = '';
    String accentWord = '';

    switch (_currentStep) {
      case OnboardingStep.businessInfo:
        fullTitle = 'TELL US ABOUT YOUR BUSINESS';
        accentWord = 'BUSINESS';
        break;
      case OnboardingStep.configureServices:
        fullTitle = 'CONFIGURE SERVICES';
        accentWord = 'SERVICES';
        break;
      case OnboardingStep.serviceDetails:
        fullTitle = 'SERVICE DETAILS';
        accentWord = 'DETAILS';
        break;
      case OnboardingStep.availability:
        fullTitle = 'SET YOUR AVAILABILITY';
        accentWord = 'AVAILABILITY';
        break;
      case OnboardingStep.verifyBusiness:
        fullTitle = 'VERIFY YOUR BUSINESS';
        accentWord = 'BUSINESS';
        break;
      case OnboardingStep.reviewBusiness:
        fullTitle = 'REVIEW YOUR BUSINESS';
        accentWord = 'BUSINESS';
        break;
      default:
        fullTitle = '';
        break;
    }

    // Rich text with orange accent
    final titleParts = fullTitle.split(accentWord);
    final richTitle = RichText(
      text: TextSpan(
        style: GoogleFonts.archivoBlack(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w500,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(text: titleParts[0]),
          if (accentWord.isNotEmpty)
            TextSpan(
              text: accentWord,
              style: const TextStyle(color: Color(0xFFE85D04)),
            ),
          if (titleParts.length > 1) TextSpan(text: titleParts[1]),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 20, top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentStep != OnboardingStep.businessInfo &&
              _currentStep != OnboardingStep.serviceDetails)
            GestureDetector(
              onTap: _goToPrevStep,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else if (_currentStep == OnboardingStep.serviceDetails)
            GestureDetector(
              onTap: () => setState(
                () => _currentStep = OnboardingStep.configureServices,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            )
          else
            const SizedBox(height: 44),

          const SizedBox(height: 16),
          richTitle,
        ],
      ),
    );
  }

  Widget _buildStepBody(Map<String, dynamic> data) {
    switch (_currentStep) {
      case OnboardingStep.businessInfo:
        return _buildBusinessInfoPage();
      case OnboardingStep.configureServices:
        return _buildConfigureServicesPage(data);
      case OnboardingStep.serviceDetails:
        return _buildServiceDetailsPage();
      case OnboardingStep.availability:
        return _buildAvailabilityPage();
      case OnboardingStep.verifyBusiness:
        return _buildVerifyBusinessPage(data);
      case OnboardingStep.reviewBusiness:
        return _buildReviewBusinessPage(data);
      case OnboardingStep.verificationPending:
        return _buildVerificationPendingPage(data);
    }
  }

  // --- PAGE 1: Business Info ---
  Widget _buildBusinessInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildPremiumInputField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'Enter your business name',
          icon: Icons.business,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _contactNameController,
          label: 'Contact Name',
          hint: 'Enter full contact name',
          icon: Icons.person,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'e.g. +919652949690',
          keyboardType: TextInputType.phone,
          icon: Icons.phone,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _locationController,
          label: 'Address / Location',
          hint: 'e.g. Ghaziabad, UP',
          icon: Icons.location_on,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _descriptionController,
          label: 'Business Description',
          hint: 'Tell pet owners about your services...',
          maxLines: 4,
          icon: Icons.description,
        ),
        const SizedBox(height: 40),
        _buildPremiumPrimaryButton(
          text: 'SAVE & CONTINUE',
          onPressed: _saveBusinessInfo,
        ),
      ],
    );
  }

  // --- PAGE 2: Configure Services ---
  Widget _buildConfigureServicesPage(Map<String, dynamic> data) {
    final servicesList = (data['services'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'List and manage the services you offer to pet owners.',
          style: GoogleFonts.barlow(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 24),
        if (servicesList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.pets, color: Colors.grey[600], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No services configured yet',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add at least one service to continue.',
                    style: GoogleFonts.barlow(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: servicesList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final s = servicesList[index] as Map<String, dynamic>;
              final sId = s['id']?.toString() ?? '';
              final name = s['name']?.toString() ?? 'Unnamed Service';
              final type = s['serviceType']?.toString() ?? '';
              final priceType = s['priceType']?.toString() ?? 'fixed';
              final price = s['price']?.toString() ?? '0';
              final minP = s['minPrice']?.toString() ?? '0';
              final maxP = s['maxPrice']?.toString() ?? '0';
              final loc = s['serviceLocation']?.toString() == 'at_my_place'
                  ? 'At my place'
                  : 'At client place';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.barlow(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Type: ${type.toUpperCase()} • $loc',
                            style: GoogleFonts.barlow(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            priceType == 'fixed'
                                ? '\$$price'
                                : '\$$minP - \$$maxP',
                            style: GoogleFonts.barlow(
                              color: const Color(0xFFE85D04),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFE85D04)),
                      onPressed: () {
                        setState(() {
                          _editingServiceId = sId;
                          _selectedServiceType = type;
                          _serviceNameController.text = name;
                          _serviceDescController.text =
                              s['description']?.toString() ?? '';
                          _durationController.text =
                              s['durationMinutes']?.toString() ?? '60';
                          _selectedPriceType = priceType;
                          _priceController.text = price;
                          _minPriceController.text = minP;
                          _maxPriceController.text = maxP;
                          _selectedServiceLocation =
                              s['serviceLocation']?.toString() ?? 'at_my_place';
                          _inclusionsList.clear();
                          if (s['inclusions'] != null) {
                            _inclusionsList.addAll(
                              List<String>.from(s['inclusions']),
                            );
                          }
                          _currentStep = OnboardingStep.serviceDetails;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => ref
                          .read(onboardingControllerProvider.notifier)
                          .deleteService(sId),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _editingServiceId = null;
              _selectedServiceType = 'groomer';
              _serviceNameController.clear();
              _serviceDescController.clear();
              _durationController.text = '60';
              _selectedPriceType = 'fixed';
              _priceController.clear();
              _minPriceController.clear();
              _maxPriceController.clear();
              _selectedServiceLocation = 'at_my_place';
              _inclusionsList.clear();
              _currentStep = OnboardingStep.serviceDetails;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFE85D04),
            side: const BorderSide(color: Color(0xFFE85D04), width: 1.8),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 22),
              const SizedBox(width: 10),
              Text(
                'ADD NEW SERVICE',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildPremiumPrimaryButton(
          text: 'CONTINUE',
          onPressed: servicesList.isNotEmpty ? _goToNextStep : null,
        ),
      ],
    );
  }

  // --- PAGE 3: Service Details ---
  Widget _buildServiceDetailsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPremiumDropdownField(
          value: _selectedServiceType,
          label: 'Service Type',
          items: const [
            DropdownMenuItem(value: 'vet', child: Text('Veterinarian')),
            DropdownMenuItem(value: 'groomer', child: Text('Groomer')),
            DropdownMenuItem(value: 'walker', child: Text('Dog Walker')),
            DropdownMenuItem(value: 'trainer', child: Text('Trainer')),
            DropdownMenuItem(value: 'sitter', child: Text('Pet Sitter')),
            DropdownMenuItem(value: 'boarding', child: Text('Boarding')),
            DropdownMenuItem(value: 'transport', child: Text('Pet Transport')),
            DropdownMenuItem(
              value: 'poop_scooper',
              child: Text('Poop Scooper'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedServiceType = val);
          },
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _serviceNameController,
          label: 'Service Name',
          hint: 'e.g. Full Grooming with Spa',
          icon: Icons.pets,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _serviceDescController,
          label: 'Description',
          hint: 'Detail what this service includes...',
          maxLines: 3,
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 20),
        _buildPremiumInputField(
          controller: _durationController,
          label: 'Duration (minutes)',
          hint: '60',
          keyboardType: TextInputType.number,
          icon: Icons.timer,
        ),
        const SizedBox(height: 20),
        _buildPremiumDropdownField(
          value: _selectedPriceType,
          label: 'Price Type',
          items: const [
            DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
            DropdownMenuItem(value: 'range', child: Text('Price Range')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedPriceType = val);
          },
        ),
        const SizedBox(height: 20),
        if (_selectedPriceType == 'fixed')
          _buildPremiumInputField(
            controller: _priceController,
            label: 'Price (\$)',
            hint: 'e.g. 40',
            keyboardType: TextInputType.number,
            icon: Icons.attach_money,
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildPremiumInputField(
                  controller: _minPriceController,
                  label: 'Min Price (\$)',
                  hint: '20',
                  keyboardType: TextInputType.number,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPremiumInputField(
                  controller: _maxPriceController,
                  label: 'Max Price (\$)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),
        _buildPremiumDropdownField(
          value: _selectedServiceLocation,
          label: 'Service Location',
          items: const [
            DropdownMenuItem(value: 'at_my_place', child: Text('At my place')),
            DropdownMenuItem(
              value: 'at_client_place',
              child: Text('At client place'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedServiceLocation = val);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Inclusions / Features',
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPremiumInputField(
                controller: _inclusionController,
                label: '',
                hint: 'e.g. Nail Trim',
                isLabelInvisible: true,
                icon: Icons.add_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE85D04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () {
                  final txt = _inclusionController.text.trim();
                  if (txt.isNotEmpty) {
                    setState(() {
                      _inclusionsList.add(txt);
                      _inclusionController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        if (_inclusionsList.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _inclusionsList.map((inc) {
              return Chip(
                label: Text(
                  inc,
                  style: GoogleFonts.barlow(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: const Color(0xFF252525),
                side: const BorderSide(color: Color(0xFFE85D04), width: 0.5),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.redAccent,
                ),
                onDeleted: () {
                  setState(() {
                    _inclusionsList.remove(inc);
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(
                  () => _currentStep = OnboardingStep.configureServices,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.barlow(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPremiumPrimaryButton(
                text: 'SAVE SERVICE',
                onPressed: _saveService,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- PAGE 4: Set Availability ---
  Widget _buildAvailabilityPage() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select days you are available to work:',
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: days.map((day) {
            final isSelected = _workingDays.contains(day);
            return FilterChip(
              label: Text(
                day,
                style: GoogleFonts.barlow(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFE85D04),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFF1F1F1F),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _workingDays.add(day);
                  } else {
                    _workingDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _startTimeController),
                child: AbsorbPointer(
                  child: _buildPremiumInputField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    hint: '09:00 AM',
                    icon: Icons.access_time,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _endTimeController),
                child: AbsorbPointer(
                  child: _buildPremiumInputField(
                    controller: _endTimeController,
                    label: 'End Time',
                    hint: '06:00 PM',
                    icon: Icons.access_time,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Same Day Requests',
                      style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accept bookings for the current day.',
                      style: GoogleFonts.barlow(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _sameDayRequests,
                onChanged: (val) => setState(() => _sameDayRequests = val),
                activeColor: const Color(0xFFE85D04),
                activeTrackColor: const Color(0xFFE85D04).withOpacity(0.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildPremiumPrimaryButton(
          text: 'SAVE & CONTINUE',
          onPressed: _saveAvailability,
        ),
      ],
    );
  }

  // --- PAGE 5: Verify Business ---
  Widget _buildVerifyBusinessPage(Map<String, dynamic> data) {
    final docs = (data['documents'] as List?) ?? [];
    final hasUploaded = docs.isNotEmpty || _selectedLicenseFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please upload your business license document to verify your account (Max 5MB).',
          style: GoogleFonts.barlow(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _isUploadingDocument ? null : _pickAndUploadLicense,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE85D04).withOpacity(0.6),
                width: 2,
              ),
            ),
            child: _isUploadingDocument
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE85D04)),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFFE85D04),
                        size: 72,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedLicenseFile == null
                            ? 'Upload Business License'
                            : 'Replace Uploaded License',
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPEG, PNG, WebP or PDF',
                        style: GoogleFonts.barlow(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),
        if (docs.isNotEmpty) ...[
          Text(
            'Uploaded Documents',
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...docs.map((d) {
            final docId = d['id']?.toString() ?? '';
            final type = d['documentType']?.toString() ?? 'business_license';
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${type.toUpperCase()} - Uploaded',
                      style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    onPressed: () => ref
                        .read(onboardingControllerProvider.notifier)
                        .deleteDocument(docId),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
        _buildPremiumPrimaryButton(
          text: 'CONTINUE',
          onPressed: hasUploaded ? _goToNextStep : null,
        ),
      ],
    );
  }

  // --- PAGE 6: Review Business ---
  // --- PAGE 6: Review Business ---
  Widget _buildReviewBusinessPage(Map<String, dynamic> data) {
    final business = (data['business'] as Map?) ?? {};
    final services = (data['services'] as List?) ?? [];
    final availability = (data['availability'] as Map?) ?? {};
    final docs = (data['documents'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please verify all your details before submitting for admin review.',
          style: GoogleFonts.barlow(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Business Information
        _buildPremiumReviewSection(
          title: 'Business Information',
          children: [
            _buildReviewRow(
              'Business Name',
              business['businessName']?.toString() ?? 'N/A',
            ),
            _buildReviewRow(
              'Contact Name',
              business['contactName']?.toString() ?? 'N/A',
            ),
            _buildReviewRow(
              'Phone Number',
              business['phone']?.toString() ?? 'N/A',
            ),
            _buildReviewRow(
              'Address',
              business['location']?.toString() ?? 'N/A',
            ),
            _buildReviewRow(
              'Description',
              business['description']?.toString() ?? 'N/A',
            ),
          ],
          onEdit: () {
            // TODO: Add edit functionality - navigate back to businessInfo step
            setState(() => _currentStep = OnboardingStep.businessInfo);
          },
        ),
        const SizedBox(height: 20),

        // Services Configured
        _buildPremiumReviewSection(
          title: 'Services Configured',
          children: services.map((s) {
            final name = s['name']?.toString() ?? 'Unnamed';
            final pType = s['priceType']?.toString() ?? 'fixed';
            final price = s['price']?.toString() ?? '0';
            final minP = s['minPrice']?.toString() ?? '0';
            final maxP = s['maxPrice']?.toString() ?? '0';
            final priceVal = pType == 'fixed'
                ? '\$$price'
                : '\$$minP - \$$maxP';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildReviewRow(
                name,
                '$priceVal (${s['durationMinutes']} mins)',
              ),
            );
          }).toList(),
          onEdit: () {
            // TODO: Add edit functionality - navigate to configureServices
            setState(() => _currentStep = OnboardingStep.configureServices);
          },
        ),
        const SizedBox(height: 20),

        // Working Schedule
        _buildPremiumReviewSection(
          title: 'Working Schedule',
          children: [
            _buildReviewRow(
              'Days',
              (availability['workingDays'] as List?)?.join(', ') ?? 'N/A',
            ),
            _buildReviewRow(
              'Hours',
              '${availability['startTime']} - ${availability['endTime']}',
            ),
            _buildReviewRow(
              'Same Day Booking',
              (availability['sameDayRequests'] as bool? ?? false)
                  ? 'Enabled'
                  : 'Disabled',
            ),
          ],
          onEdit: () {
            // TODO: Add edit functionality - navigate to availability
            setState(() => _currentStep = OnboardingStep.availability);
          },
        ),
        const SizedBox(height: 20),

        // Verification Documents
        _buildPremiumReviewSection(
          title: 'Verification Documents',
          children: [
            _buildReviewRow('Documents Uploaded', '${docs.length} File(s)'),
          ],
          onEdit: () {
            // TODO: Add edit functionality - navigate to verifyBusiness
            setState(() => _currentStep = OnboardingStep.verifyBusiness);
          },
        ),

        const SizedBox(height: 32),

        // Security Note (as per your screenshot)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFFE85D04),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Your information is secure and will only used to verify your business',
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        _buildPremiumPrimaryButton(
          text: 'SUBMIT APPLICATION',
          onPressed: _submitApplication,
        ),
      ],
    );
  }

  // --- PAGE 7: Verification Pending ---
  // --- PAGE 7: Verification Pending ---
  Widget _buildVerificationPendingPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hourglass with confetti effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Confetti dots
              Positioned(
                left: 40,
                top: 20,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 50,
                top: 35,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 70,
                bottom: 40,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: 25,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.purple[400],
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Main Hourglass Circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE85D04),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE85D04).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.hourglass_bottom,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            'VERIFICATION PENDING',
            style: GoogleFonts.archivoBlack(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Our team has received your application.\nThis usually takes 24-48 hours.',
            style: GoogleFonts.barlow(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildStatusRow('Business Information', 'Submitted', true),
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildStatusRow('Services Configured', 'Completed', true),
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildStatusRow('Documentation Upload', 'Completed', true),
                const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildStatusRow(
                  'Verification',
                  'In Process',
                  false,
                  isWarning: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          _buildPremiumPrimaryButton(
            text: 'GO TO DASHBOARD',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper for status rows
  Widget _buildStatusRow(
    String title,
    String status,
    bool isCompleted, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.error_outline,
            color: isCompleted
                ? Colors.green
                : (isWarning ? Colors.orange : Colors.grey),
            size: 26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.barlow(
                    color: isCompleted
                        ? Colors.green[300]
                        : (isWarning ? Colors.orange[300] : Colors.grey[500]),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- PREMIUM HELPER WIDGETS ---

  Widget _buildPremiumInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isLabelInvisible = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLabelInvisible) ...[
          Text(
            label,
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.barlow(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.barlow(
              color: Colors.grey[600],
              fontSize: 15.5,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey[500], size: 22)
                : null,
            filled: true,
            fillColor: const Color(0xFF1F1F1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE85D04),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdownField({
    required String value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            dropdownColor: const Color(0xFF1F1F1F),
            style: GoogleFonts.barlow(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumReviewSection({
    required String title,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  color: const Color(0xFFE85D04),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE85D04),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.barlow(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.barlow(color: Colors.white, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE85D04),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE85D04).withOpacity(0.5),
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        shadowColor: const Color(0xFFE85D04).withOpacity(0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.barlow(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
