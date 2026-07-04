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
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
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
      print('DEBUG: [OnboardingFlowScreen._populateFromState] Populate data: $data');
      
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
      print('DEBUG: [OnboardingFlowScreen._populateFromState] Error populating fields: $e\n$stack');
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
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
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

      print('DEBUG: [OnboardingFlowScreen] Selected file path: ${file.path}. Starting upload...');
      final success = await ref.read(onboardingControllerProvider.notifier).uploadDocument(
            _selectedLicenseFile!,
            'business_license',
          );

      if (mounted) {
        setState(() {
          _isUploadingDocument = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document uploaded successfully!', style: GoogleFonts.barlow()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _selectedLicenseFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload document.', style: GoogleFonts.barlow()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e, stack) {
      print('DEBUG: [OnboardingFlowScreen] Upload failed with error: $e\n$stack');
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

    if (businessName.isEmpty || contactName.isEmpty || phone.isEmpty || location.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref.read(onboardingControllerProvider.notifier).saveBusinessInfo(
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
          content: Text('Please enter service name and description', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedPriceType == 'fixed' && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedPriceType == 'range' && (minPrice == null || maxPrice == null || minPrice >= maxPrice)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price range', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    bool success = false;
    if (_editingServiceId == null) {
      // Add Service
      success = await ref.read(onboardingControllerProvider.notifier).addService(
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
          content: Text('Please select at least one working day', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref.read(onboardingControllerProvider.notifier).saveAvailability(
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
    final success = await ref.read(onboardingControllerProvider.notifier).submitApplication();
    if (success && mounted) {
      _goToNextStep();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application. Please review details.', style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        await ref.read(authControllerProvider.notifier).forgotPassword(email: ''); // just placeholder or force clear
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
      backgroundColor: Colors.black,
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
                    style: GoogleFonts.barlow(color: Colors.redAccent, fontSize: 16),
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
                    child: Text('Log Out', style: GoogleFonts.barlow(color: const Color(0xFFE85D04))),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final parsedData = data ?? {};
            return Column(
              children: [
                if (_currentStep != OnboardingStep.verificationPending) _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    String stepTitle = '';
    int stepNumber = 1;
    int totalSteps = 6;

    switch (_currentStep) {
      case OnboardingStep.businessInfo:
        stepTitle = 'Tell us about your business';
        stepNumber = 1;
        break;
      case OnboardingStep.configureServices:
        stepTitle = 'Configure services';
        stepNumber = 2;
        break;
      case OnboardingStep.serviceDetails:
        stepTitle = 'Service details';
        stepNumber = 3;
        break;
      case OnboardingStep.availability:
        stepTitle = 'Set your availability';
        stepNumber = 4;
        break;
      case OnboardingStep.verifyBusiness:
        stepTitle = 'Verify your business';
        stepNumber = 5;
        break;
      case OnboardingStep.reviewBusiness:
        stepTitle = 'Review your business';
        stepNumber = 6;
        break;
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep != OnboardingStep.businessInfo && _currentStep != OnboardingStep.serviceDetails)
                GestureDetector(
                  onTap: _goToPrevStep,
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                )
              else if (_currentStep == OnboardingStep.serviceDetails)
                GestureDetector(
                  onTap: () => setState(() => _currentStep = OnboardingStep.configureServices),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                )
              else
                const SizedBox(width: 20),
              
              Text(
                'Step $stepNumber of $totalSteps',
                style: GoogleFonts.barlow(
                  color: const Color(0xFFE85D04),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            stepTitle.toUpperCase(),
            style: GoogleFonts.archivoBlack(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: stepNumber / totalSteps,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D04),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
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
        const SizedBox(height: 12),
        _buildInputField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'Enter your business name',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _contactNameController,
          label: 'Contact Name',
          hint: 'Enter full contact name',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'e.g. +919652949690',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _locationController,
          label: 'Address / Location',
          hint: 'e.g. Ghaziabad, UP',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _descriptionController,
          label: 'Business Description',
          hint: 'Tell pet owners about your services...',
          maxLines: 4,
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
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
          style: GoogleFonts.barlow(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (servicesList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.pets, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No services configured yet',
                    style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add at least one service to continue.',
                    style: GoogleFonts.barlow(color: Colors.grey, fontSize: 13),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = servicesList[index] as Map<String, dynamic>;
              final sId = s['id']?.toString() ?? '';
              final name = s['name']?.toString() ?? 'Unnamed Service';
              final type = s['serviceType']?.toString() ?? '';
              final priceType = s['priceType']?.toString() ?? 'fixed';
              final price = s['price']?.toString() ?? '0';
              final minP = s['minPrice']?.toString() ?? '0';
              final maxP = s['maxPrice']?.toString() ?? '0';
              final loc = s['serviceLocation']?.toString() == 'at_my_place' ? 'At my place' : 'At client place';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type: ${type.toUpperCase()} · Location: $loc',
                            style: GoogleFonts.barlow(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            priceType == 'fixed' ? '\$$price' : '\$$minP - \$$maxP',
                            style: GoogleFonts.barlow(color: const Color(0xFFE85D04), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () {
                        setState(() {
                          _editingServiceId = sId;
                          _selectedServiceType = type;
                          _serviceNameController.text = name;
                          _serviceDescController.text = s['description']?.toString() ?? '';
                          _durationController.text = s['durationMinutes']?.toString() ?? '60';
                          _selectedPriceType = priceType;
                          _priceController.text = price;
                          _minPriceController.text = minP;
                          _maxPriceController.text = maxP;
                          _selectedServiceLocation = s['serviceLocation']?.toString() ?? 'at_my_place';
                          _inclusionsList.clear();
                          if (s['inclusions'] != null) {
                            _inclusionsList.addAll(List<String>.from(s['inclusions']));
                          }
                          _currentStep = OnboardingStep.serviceDetails;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => ref.read(onboardingControllerProvider.notifier).deleteService(sId),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 20),
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
            side: const BorderSide(color: Color(0xFFE85D04), width: 1.5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text('ADD SERVICE', style: GoogleFonts.barlow(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
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
        _buildDropdownField(
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
            DropdownMenuItem(value: 'poop_scooper', child: Text('Poop Scooper')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedServiceType = val);
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _serviceNameController,
          label: 'Service Name',
          hint: 'e.g. Full Grooming with Spa',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _serviceDescController,
          label: 'Description',
          hint: 'Detail what this service includes...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _durationController,
          label: 'Duration (minutes)',
          hint: '60',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
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
        const SizedBox(height: 16),
        if (_selectedPriceType == 'fixed')
          _buildInputField(
            controller: _priceController,
            label: 'Price (\$)',
            hint: 'e.g. 40',
            keyboardType: TextInputType.number,
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _minPriceController,
                  label: 'Min Price (\$)',
                  hint: '20',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _maxPriceController,
                  label: 'Max Price (\$)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),
        _buildDropdownField(
          value: _selectedServiceLocation,
          label: 'Service Location',
          items: const [
            DropdownMenuItem(value: 'at_my_place', child: Text('At my place')),
            DropdownMenuItem(value: 'at_client_place', child: Text('At client place')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedServiceLocation = val);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Inclusions / Features',
          style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _inclusionController,
                label: '',
                hint: 'e.g. Nail Trim',
                isLabelInvisible: true,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final txt = _inclusionController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _inclusionsList.add(txt);
                    _inclusionController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(60, 50),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        if (_inclusionsList.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inclusionsList.map((inc) {
              return Chip(
                label: Text(inc, style: GoogleFonts.barlow(color: Colors.white, fontSize: 12)),
                backgroundColor: const Color(0xFF232323),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                onDeleted: () {
                  setState(() {
                    _inclusionsList.remove(inc);
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentStep = OnboardingStep.configureServices),
                child: Text('CANCEL', style: GoogleFonts.barlow(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPrimaryButton(
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
          style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            final isSelected = _workingDays.contains(day);
            return FilterChip(
              label: Text(day, style: GoogleFonts.barlow(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: const Color(0xFFE85D04),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFF232323),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _startTimeController),
                child: AbsorbPointer(
                  child: _buildInputField(
                    controller: _startTimeController,
                    label: 'Start Time',
                    hint: '09:00 AM',
                    suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, _endTimeController),
                child: AbsorbPointer(
                  child: _buildInputField(
                    controller: _endTimeController,
                    label: 'End Time',
                    hint: '06:00 PM',
                    suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
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
                      style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accept bookings for the current day.',
                      style: GoogleFonts.barlow(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _sameDayRequests,
                onChanged: (val) => setState(() => _sameDayRequests = val),
                activeColor: const Color(0xFFE85D04),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
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
          style: GoogleFonts.barlow(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _isUploadingDocument ? null : _pickAndUploadLicense,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE85D04).withOpacity(0.5),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: _isUploadingDocument
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE85D04)))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: Color(0xFFE85D04), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _selectedLicenseFile == null ? 'Upload Business License' : 'Replace Uploaded License',
                        style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Supports JPEG, PNG, WebP or PDF',
                        style: GoogleFonts.barlow(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        if (docs.isNotEmpty) ...[
          Text(
            'Uploaded Document:',
            style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...docs.map((d) {
            final docId = d['id']?.toString() ?? '';
            final type = d['documentType']?.toString() ?? 'business_license';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${type.toUpperCase()} - Uploaded',
                      style: GoogleFonts.barlow(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: () => ref.read(onboardingControllerProvider.notifier).deleteDocument(docId),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
        _buildPrimaryButton(
          text: 'CONTINUE',
          onPressed: hasUploaded ? _goToNextStep : null,
        ),
      ],
    );
  }

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
          style: GoogleFonts.barlow(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildReviewSection(
          title: 'Business Information',
          children: [
            _buildReviewRow('Business Name', business['businessName']?.toString() ?? 'N/A'),
            _buildReviewRow('Contact Name', business['contactName']?.toString() ?? 'N/A'),
            _buildReviewRow('Phone Number', business['phone']?.toString() ?? 'N/A'),
            _buildReviewRow('Address', business['location']?.toString() ?? 'N/A'),
            _buildReviewRow('Description', business['description']?.toString() ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          title: 'Services Configured',
          children: services.map((s) {
            final name = s['name']?.toString() ?? 'Unnamed';
            final pType = s['priceType']?.toString() ?? 'fixed';
            final price = s['price']?.toString() ?? '0';
            final minP = s['minPrice']?.toString() ?? '0';
            final maxP = s['maxPrice']?.toString() ?? '0';
            final priceVal = pType == 'fixed' ? '\$$price' : '\$$minP - \$$maxP';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildReviewRow(name, '$priceVal (${s['durationMinutes']} mins)'),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          title: 'Working Schedule',
          children: [
            _buildReviewRow('Days', (availability['workingDays'] as List?)?.join(', ') ?? 'N/A'),
            _buildReviewRow('Hours', '${availability['startTime']} - ${availability['endTime']}'),
            _buildReviewRow('Same Day Booking', (availability['sameDayRequests'] as bool? ?? false) ? 'Enabled' : 'Disabled'),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewSection(
          title: 'Verification Documents',
          children: [
            _buildReviewRow('Documents Uploaded', '${docs.length} File(s)'),
          ],
        ),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          text: 'SUBMIT APPLICATION',
          onPressed: _submitApplication,
        ),
      ],
    );
  }

  // --- PAGE 7: Verification Pending ---
  Widget _buildVerificationPendingPage(Map<String, dynamic> data) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFFE85D04), size: 84),
            const SizedBox(height: 24),
            Text(
              'VERIFICATION PENDING',
              style: GoogleFonts.archivoBlack(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for submitting your application!\nOur admin team is currently reviewing your profile.\nVerification normally takes 24–48 hours.',
              style: GoogleFonts.barlow(color: Colors.grey, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildPrimaryButton(
              text: 'GO TO HOME PAGE',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _handleLogout,
              child: Text(
                'Log Out',
                style: GoogleFonts.barlow(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER COMPONENT BUILDERS ---

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool isLabelInvisible = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLabelInvisible) ...[
          Text(
            label,
            style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.barlow(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.barlow(color: Colors.grey, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: const Color(0xFF232323),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
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
          style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF232323),
              style: GoogleFonts.barlow(color: Colors.white),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.barlow(color: const Color(0xFFE85D04), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(color: Colors.grey, height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.barlow(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.barlow(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE85D04),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE85D04).withOpacity(0.5),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.barlow(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
