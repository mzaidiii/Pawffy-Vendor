import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart' as dio;

import 'package:pawffy/main.dart';
import '../data/models/request_model.dart';
import '../providers/requests_controller.dart';
import 'package:pawffy/core/utils/image_picker_helper.dart';

class RequestDetailsScreen extends ConsumerStatefulWidget {
  final RequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _inProgress = false;
  bool _isEnding = false; // Used for Walking/Training final screens

  // Timer fields for in-progress states
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  // Location streaming fields for walking
  Timer? _locationStreamTimer;
  Position? _currentPosition;
  String _currentAddress = 'Fetching...';

  // State fields for Video Consultation
  TabController? _tabController;
  final _clinicalNotesController = TextEditingController();
  final _diagnosticsController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _consultSummaryController = TextEditingController();
  File? _prescriptionFile;
  bool _followUpRequired = false;
  DateTime? _followUpDate;

  // State fields for Grooming
  final Map<String, bool> _groomingMilestones = {
    'Bath': true,
    'Hair Cut': false,
    'Nail trim': false,
    'Blow dry': false,
    'De-Shedding': false,
  };
  final List<File> _groomingPhotos = [];
  final _groomingSummaryController = TextEditingController();

  // State fields for Dog Walking
  final _walkSummaryController = TextEditingController();
  final List<File> _walkPhotos = [];
  String _selectedMood = 'happy'; // happy, normal, bad

  // State fields for Training
  final Map<String, bool> _trainingMilestones = {
    'Focus & Attention': true,
    'Sit Command': false,
    'Stay Command': false,
    'Loose leash Walking': false,
    'Come Command': false,
  };
  final _trainingNotesController = TextEditingController();
  final List<File> _trainingPhotos = [];
  final _trainingSummaryController = TextEditingController();
  final _trainingExerciseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.request.serviceType == 'vet' || widget.request.serviceName.toLowerCase().contains('consult')) {
      _tabController = TabController(length: 3, vsync: this);
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _locationStreamTimer?.cancel();
    _tabController?.dispose();
    _clinicalNotesController.dispose();
    _diagnosticsController.dispose();
    _treatmentsController.dispose();
    _consultSummaryController.dispose();
    _groomingSummaryController.dispose();
    _walkSummaryController.dispose();
    _trainingNotesController.dispose();
    _trainingSummaryController.dispose();
    _trainingExerciseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startLocationStreaming() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      _locationStreamTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          setState(() {
            _currentPosition = pos;
            _currentAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          });

          await ref.read(requestsNotifierProvider.notifier).updateLocation(
                widget.request.id,
                latitude: pos.latitude,
                longitude: pos.longitude,
                address: 'Active Walk Path',
              );
        } catch (_) {}
      });
    } catch (_) {}
  }

  String _formatDuration(int totalSeconds) {
    final hrs = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }

  Future<void> _handleAccept(String id) async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);
    final success = await notifier.acceptRequest(id);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept request.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String id) async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);
    final success = await notifier.rejectRequest(id);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject request.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleStartService(String id) async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);
    final success = await notifier.startRequest(id);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        setState(() {
          _inProgress = true;
        });
        _startTimer();
        if (widget.request.serviceType == 'walker' || widget.request.serviceName.toLowerCase().contains('walk')) {
          _startLocationStreaming();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service started successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start service.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteGrooming() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': _groomingSummaryController.text.trim(),
      'milestones': _groomingMilestones.toString(),
    });

    for (var file in _groomingPhotos) {
      final name = file.path.split(Platform.pathSeparator).last;
      formData.files.add(
        MapEntry(
          'media',
          await dio.MultipartFile.fromFile(file.path, filename: name),
        ),
      );
    }

    final success = await notifier.completeRequest(widget.request.id, formData);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grooming service completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete service.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteWalk() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': _walkSummaryController.text.trim(),
      'petMood': _selectedMood,
      'durationMinutes': (_elapsedSeconds ~/ 60) > 0 ? (_elapsedSeconds ~/ 60) : 1,
    });

    for (var file in _walkPhotos) {
      final name = file.path.split(Platform.pathSeparator).last;
      formData.files.add(
        MapEntry(
          'walkPhotos',
          await dio.MultipartFile.fromFile(file.path, filename: name),
        ),
      );
    }

    final success = await notifier.completeRequest(widget.request.id, formData);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Walk completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete walk.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteTraining() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final exercises = _trainingExerciseController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final formData = dio.FormData.fromMap({
      'summary': _trainingSummaryController.text.trim(),
      'sessionNotes': _trainingNotesController.text.trim(),
      'assignedExercises': exercises.join(', '),
      'focusAreas': _trainingMilestones.toString(),
    });

    for (var file in _trainingPhotos) {
      final name = file.path.split(Platform.pathSeparator).last;
      formData.files.add(
        MapEntry(
          'mediaUrls',
          await dio.MultipartFile.fromFile(file.path, filename: name),
        ),
      );
    }

    final success = await notifier.completeRequest(widget.request.id, formData);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training session completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete session.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteVet() async {
    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'clinicalNotes': _clinicalNotesController.text.trim(),
      'diagnostics': _diagnosticsController.text.trim(),
      'treatments': _treatmentsController.text.trim(),
      'summary': _consultSummaryController.text.trim(),
      'followUpRequired': _followUpRequired.toString(),
      if (_followUpDate != null) 'followUpDate': _followUpDate!.toIso8601String().split('T').first,
    });

    if (_prescriptionFile != null) {
      final name = _prescriptionFile!.path.split(Platform.pathSeparator).last;
      formData.files.add(
        MapEntry(
          'prescriptionFile',
          await dio.MultipartFile.fromFile(_prescriptionFile!.path, filename: name),
        ),
      );
    }

    final success = await notifier.completeRequest(widget.request.id, formData);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veterinary Consultation Completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete consultation.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildMoodBtn(String mood, String label, Color color) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req = widget.request;
    final hasPetPhoto = req.pet?.photo != null && req.pet!.photo!.isNotEmpty;

    // Detect Service Type
    final isWalk = req.serviceType == 'walker' || req.serviceName.toLowerCase().contains('walk');
    final isGroom = req.serviceType == 'groomer' || req.serviceName.toLowerCase().contains('groom');
    final isTrain = req.serviceType == 'trainer' || req.serviceName.toLowerCase().contains('train');
    final isVet = req.serviceType == 'vet' || req.serviceName.toLowerCase().contains('consult');

    String pageTitle = 'REQUEST DETAILS';
    if (_inProgress) {
      if (isWalk) {
        pageTitle = _isEnding ? 'END WALK' : 'WALK IN PROGRESS';
      } else if (isGroom) {
        pageTitle = 'GROOMING IN PROGRESS';
      } else if (isTrain) {
        pageTitle = _isEnding ? 'END TRAINING' : 'TRAINING IN PROGRESS';
      } else if (isVet) {
        pageTitle = 'APPOINTMENT COMPLETE';
      }
    } else if (req.status == 'upcoming') {
      if (isWalk) {
        pageTitle = 'WALK DETAILS';
      } else {
        pageTitle = 'APPOINTMENT DETAILS';
      }
    }

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
          onPressed: () {
            if (_isEnding) {
              setState(() => _isEnding = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          pageTitle,
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
                    // --- PET OVERVIEW CARD ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasPetPhoto
                                ? CachedNetworkImage(
                                    imageUrl: req.pet!.photo!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _buildFallbackAvatar(req.pet?.name ?? 'P'),
                                  )
                                : _buildFallbackAvatar(req.pet?.name ?? 'P'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.pet?.name ?? 'Unknown Pet',
                                  style: GoogleFonts.barlow(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${req.pet?.age ?? "Age unknown"} • ${req.pet?.gender ?? "Gender unknown"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  req.pet?.breed ?? 'Breed unknown',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- SCREEN FLOWS ---
                    if (!_inProgress) ...[
                      // standard preview details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Service', req.serviceName, isDark),
                            if (!isVet) ...[
                              _buildDivider(isDark),
                              _buildDetailRow('Type', 'In Person', isDark),
                            ],
                            _buildDivider(isDark),
                            _buildDetailRow('Date & Time', req.time, isDark),
                            _buildDivider(isDark),
                            _buildDetailRow('Duration', '${req.durationMinutes} Minutes', isDark),
                            if (req.issues != null) ...[
                              _buildDivider(isDark),
                              _buildDetailRow('Issues', req.issues!, isDark),
                            ],
                            if (req.notes != null) ...[
                              _buildDivider(isDark),
                              _buildDetailRow('Owners Note', req.notes!, isDark),
                            ],
                            _buildDivider(isDark),
                            _buildDetailRowWithMapButton('Location', req.location, isDark, showMap: !isVet),
                            if (req.price > 0) ...[
                              _buildDivider(isDark),
                              _buildDetailRow('Payment', req.priceDisplay, isDark),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // In Progress UI Mocks
                      if (isVet) _buildVetInProgress(isDark),
                      if (isGroom) _buildGroomInProgress(isDark),
                      if (isWalk) _buildWalkInProgress(isDark),
                      if (isTrain) _buildTrainInProgress(isDark),
                    ],
                  ],
                ),
              ),
            ),

            // --- BOTTOM ACTIONS BAR ---
            if (!_inProgress) ...[
              if (req.status == 'pending')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessing ? null : () => _handleAccept(req.id),
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('ACCEPT REQUEST'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessing ? null : () => _handleReject(req.id),
                          child: Text(
                            'REJECT REQUEST',
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (req.status == 'upcoming')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessing ? null : () => _handleStartService(req.id),
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isVet
                                  ? 'START CONSULTATION'
                                  : (isGroom
                                      ? 'START GROOMING'
                                      : (isWalk ? 'START WALK' : 'START SESSION'))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.orange, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat window opening...')),
                            );
                          },
                          child: const Text(
                            'MESSAGE',
                            style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: req.status == 'completed'
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Request Status: ${req.status.toUpperCase()}',
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: req.status == 'completed' ? Colors.blue : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              if (isGroom)
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
                      onPressed: _isProcessing ? null : _handleCompleteGrooming,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('COMPLETE GROOMING'),
                    ),
                  ),
                ),
              if (isWalk)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  if (_isEnding) {
                                    _handleCompleteWalk();
                                  } else {
                                    setState(() {
                                      _isEnding = true;
                                    });
                                  }
                                },
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isEnding ? 'COMPLETE WALK' : 'END WALK'),
                        ),
                      ),
                      if (!_isEnding) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.orange, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {},
                            child: const Text('MESSAGE', style: TextStyle(color: AppColors.orange)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (isTrain)
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
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (_isEnding) {
                                _handleCompleteTraining();
                              } else {
                                setState(() {
                                  _isEnding = true;
                                });
                              }
                            },
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isEnding ? 'COMPLETE SESSION' : 'COMPLETE SESSION'),
                    ),
                  ),
                ),
              if (isVet)
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
                      onPressed: _isProcessing ? null : _handleCompleteVet,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE NOTES'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // --- SERVICE PROGRESS BUILDERS ---

  Widget _buildVetInProgress(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.orange,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: AppColors.orange,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Chats'),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Notes Tab
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _clinicalNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Observed mild dehydration and gastric symptoms.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Diagnostics', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _diagnosticsController,
                    decoration: const InputDecoration(
                      hintText: 'Acute gastric',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Treatments', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _treatmentsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'ORS for hydration. Light diet recommended.',
                    ),
                  ),
                ],
              ),

              // Prescriptions Tab
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _consultSummaryController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Pet showed improvement advised to continue medication for 2 days...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Upload Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_prescriptionFile != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _prescriptionFile!.path.split(Platform.pathSeparator).last,
                                style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _prescriptionFile = null),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          final file = await ImagePickerHelper.pickImageWithPermission(
                            context: context,
                            source: ImageSource.gallery,
                          );
                          if (file != null) {
                            setState(() => _prescriptionFile = File(file.path));
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: AppColors.orange),
                                SizedBox(width: 8),
                                Text('Add New Prescription', style: TextStyle(color: AppColors.orange)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Follow-up Required?', style: TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: _followUpRequired,
                          activeColor: AppColors.orange,
                          onChanged: (val) => setState(() => _followUpRequired = val),
                        ),
                      ],
                    ),
                    if (_followUpRequired) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 2)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (selected != null) {
                            setState(() => _followUpDate = selected);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_followUpDate == null
                                  ? 'Select Date'
                                  : _followUpDate!.toLocal().toString().split(' ').first),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              // Chats Tab (Placeholder)
              const Center(child: Text('Consultation Chat logs will display here.')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroomInProgress(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Progress',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: _groomingMilestones.keys.map((key) {
              return CheckboxListTile(
                title: Text(key, style: const TextStyle(fontSize: 14)),
                value: _groomingMilestones[key],
                activeColor: AppColors.orange,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _groomingMilestones[key] = val ?? false;
                  });
                  ref.read(requestsNotifierProvider.notifier).updateProgress(
                    widget.request.id,
                    {'milestones': _groomingMilestones},
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Add Photos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._groomingPhotos.map((file) {
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  final file = await ImagePickerHelper.pickImageWithPermission(
                    context: context,
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    setState(() {
                      _groomingPhotos.add(File(file.path));
                    });
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Service Summary',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _groomingSummaryController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Full Grooming Completed. Buddy is clean. Nail is trimmed...',
          ),
        ),
      ],
    );
  }

  Widget _buildWalkInProgress(bool isDark) {
    if (_isEnding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walk Summary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _walkSummaryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Buddy was friendly and enjoyed the walk...',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Add Photos',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._walkPhotos.map((file) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () async {
                    final file = await ImagePickerHelper.pickImageWithPermission(
                      context: context,
                      source: ImageSource.gallery,
                    );
                    if (file != null) {
                      setState(() {
                        _walkPhotos.add(File(file.path));
                      });
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Pet Mood',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodBtn('happy', '😊 Happy', AppColors.success),
              _buildMoodBtn('normal', '😐 Normal', AppColors.orange),
              _buildMoodBtn('bad', '😢 Bad', AppColors.error),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Center(
          child: Text(
            _formatDuration(_elapsedSeconds),
            style: GoogleFonts.barlow(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.orange),
          ),
        ),
        const Center(
          child: Text('Time Elapse', style: TextStyle(color: AppColors.grey)),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duration', style: TextStyle(color: AppColors.grey)),
                Text('${widget.request.durationMinutes} minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Start Time', style: TextStyle(color: AppColors.grey)),
                Text(widget.request.time.split(',').last.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Live Location', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 4),
              const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: MapPathPainter(),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      _currentAddress,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.orange),
          label: const Text('Add File', style: TextStyle(color: AppColors.orange)),
        )
      ],
    );
  }

  Widget _buildTrainInProgress(bool isDark) {
    if (_isEnding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Summary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _trainingSummaryController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Great Session! Buddy showed good improvement in focus...',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Assign Exercise to Pet\'s Parent',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _trainingExerciseController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '• Regular Practice of sit and stay\n• Loose leash walks...',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Add Media',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._trainingPhotos.map((file) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () async {
                    final file = await ImagePickerHelper.pickImageWithPermission(
                      context: context,
                      source: ImageSource.gallery,
                    );
                    if (file != null) {
                      setState(() {
                        _trainingPhotos.add(File(file.path));
                      });
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            _formatDuration(_elapsedSeconds),
            style: GoogleFonts.barlow(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.orange),
          ),
        ),
        const Center(
          child: Text('Expected Time', style: TextStyle(color: AppColors.grey)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Focus Areas',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: _trainingMilestones.keys.map((key) {
              return CheckboxListTile(
                title: Text(key, style: const TextStyle(fontSize: 14)),
                value: _trainingMilestones[key],
                activeColor: AppColors.orange,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _trainingMilestones[key] = val ?? false;
                  });
                  ref.read(requestsNotifierProvider.notifier).updateProgress(
                    widget.request.id,
                    {'focusAreas': _trainingMilestones},
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Session Notes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _trainingNotesController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Buddy is responding well to positive reinforcement...',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Add Media',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._trainingPhotos.map((file) {
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  final file = await ImagePickerHelper.pickImageWithPermission(
                    context: context,
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    setState(() {
                      _trainingPhotos.add(File(file.path));
                    });
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DETAIL ROW BUILDERS ---
  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithMapButton(String label, String value, bool isDark, {required bool showMap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (showMap) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: const Size(90, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Location Map view...')),
                );
              },
              child: Text(
                'VIEW IN MAP',
                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.barlow(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

// Custom Painter to render stylized map tracking paths
class MapPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black87;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    final pathPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(30, size.height - 40);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.4, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width - 40, size.height * 0.3);
    canvas.drawPath(path, pathPaint);

    final dotPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.3), 6, dotPaint);

    final pulsePaint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.3), 12, pulsePaint);

    const textStyle = TextStyle(color: Colors.white30, fontSize: 9);
    final textPainter1 = TextPainter(
      text: const TextSpan(text: 'Main Street', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter1.paint(canvas, Offset(size.width * 0.1, size.height * 0.6));

    final textPainter2 = TextPainter(
      text: const TextSpan(text: 'The Park Lane', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter2.paint(canvas, Offset(size.width * 0.65, size.height * 0.45));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
