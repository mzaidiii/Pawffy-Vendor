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
import 'package:pawffy/features/reviews/providers/reviews_controller.dart';
import 'package:pawffy/core/Storage/storage_service.dart';

class RequestDetailsScreen extends ConsumerStatefulWidget {
  final RequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen>
    with SingleTickerProviderStateMixin {
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

  // State fields for Other Services
  final _otherSummaryController = TextEditingController();
  final List<File> _otherPhotos = [];

  @override
  void initState() {
    super.initState();
    if (widget.request.serviceType == 'vet' ||
        widget.request.serviceName.toLowerCase().contains('consult')) {
      _tabController = TabController(length: 3, vsync: this);
    }

    // Restore active session state if booking is in progress on server
    final status = widget.request.status.toLowerCase();
    if (status == 'in_progress' ||
        status == 'in-progress' ||
        status == 'started' ||
        status == 'ongoing' ||
        status == 'active') {
      _initActiveSessionTimer();
    }
  }

  Future<void> _initActiveSessionTimer() async {
    _inProgress = true;
    final savedStartMs = await StorageService.getSessionStartTime(
      widget.request.id,
    );
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (savedStartMs != null) {
      final diffSec = (nowMs - savedStartMs) ~/ 1000;
      _elapsedSeconds = diffSec > 0 ? diffSec : 0;
    } else {
      await StorageService.saveSessionStartTime(widget.request.id, nowMs);
      _elapsedSeconds = 0;
    }
    if (mounted) {
      setState(() {});
    }
    _startTimer();
    final isWalk =
        widget.request.serviceType?.toLowerCase() == 'walker' ||
        widget.request.serviceName.toLowerCase().contains('walk');
    if (isWalk) {
      _startLocationStreaming();
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
    _otherSummaryController.dispose();
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _locationStreamTimer = Timer.periodic(const Duration(seconds: 20), (
        timer,
      ) async {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          setState(() {
            _currentPosition = pos;
            _currentAddress =
                '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          });

          await ref
              .read(requestsNotifierProvider.notifier)
              .updateLocation(
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

  Future<void> _handleReject(String id) async {
    setState(() => _isProcessing = true);
    try {
      final notifier = ref.read(requestsNotifierProvider.notifier);
      final success = await notifier.rejectRequest(id);
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
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleStartService(String id) async {
    setState(() => _isProcessing = true);
    try {
      final notifier = ref.read(requestsNotifierProvider.notifier);
      final success = await notifier.startRequest(id);
      if (mounted) {
        if (success) {
          await StorageService.saveSessionStartTime(
            id,
            DateTime.now().millisecondsSinceEpoch,
          );
          setState(() {
            _inProgress = true;
            _elapsedSeconds = 0;
          });
          _startTimer();
          if (widget.request.serviceType == 'walker' ||
              widget.request.serviceName.toLowerCase().contains('walk')) {
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
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        final lower = errorMsg.toLowerCase();
        if (lower.contains('already') ||
            lower.contains('in_progress') ||
            lower.contains('in progress') ||
            lower.contains('started')) {
          await _initActiveSessionTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Session is already in progress. Loaded active session!',
              ),
              backgroundColor: AppColors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCompleteGrooming() async {
    final summary = _groomingSummaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session summary is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': summary,
      'milestones': _groomingMilestones.toString(),
    });

    try {
      final success = await notifier.completeRequest(
        widget.request.id,
        formData,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          await StorageService.clearSessionStartTime(widget.request.id);
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
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCompleteOther() async {
    final summary = _otherSummaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service summary is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': summary,
      'notes': summary,
    });

    try {
      final success = await notifier.completeRequest(
        widget.request.id,
        formData,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          await StorageService.clearSessionStartTime(widget.request.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service completed successfully!'),
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
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCompleteWalk() async {
    final summary = _walkSummaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walk summary is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet mood selection is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': summary,
      'petMood': _selectedMood,
      'durationMinutes': (_elapsedSeconds ~/ 60) > 0
          ? (_elapsedSeconds ~/ 60)
          : 1,
    });

    try {
      final success = await notifier.completeRequest(
        widget.request.id,
        formData,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          await StorageService.clearSessionStartTime(widget.request.id);
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
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCompleteTraining() async {
    final summary = _trainingSummaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session summary is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final sessionNotes = _trainingNotesController.text.trim();
    if (sessionNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session notes are required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final exercises = _trainingExerciseController.text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please assign at least one exercise for the pet parent!',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'summary': summary,
      'sessionNotes': sessionNotes,
      'focusAreas': _trainingMilestones.toString(),
      'assignedExercises': exercises,
    });

    for (var ex in exercises) {
      formData.fields.add(MapEntry('assignedExercises', ex));
      formData.fields.add(MapEntry('assignedExercises[]', ex));
    }

    try {
      final success = await notifier.completeRequest(
        widget.request.id,
        formData,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          await StorageService.clearSessionStartTime(widget.request.id);
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
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCompleteVet() async {
    final summary = _consultSummaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation summary is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final clinicalNotes = _clinicalNotesController.text.trim();
    if (clinicalNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinical notes are required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final diagnostics = _diagnosticsController.text.trim();
    if (diagnostics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostics information is required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final treatments = _treatmentsController.text.trim();
    if (treatments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment recommendations are required!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final notifier = ref.read(requestsNotifierProvider.notifier);

    final formData = dio.FormData.fromMap({
      'clinicalNotes': clinicalNotes,
      'diagnostics': diagnostics,
      'treatments': treatments,
      'summary': summary,
      'followUpRequired': _followUpRequired.toString(),
      if (_followUpDate != null)
        'followUpDate': _followUpDate!.toIso8601String().split('T').first,
    });

    try {
      final success = await notifier.completeRequest(
        widget.request.id,
        formData,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          await StorageService.clearSessionStartTime(widget.request.id);
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
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
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
    final writtenReviewsAsync = ref.watch(writtenReviewsProvider);
    final hasPetPhoto = req.pet?.photo != null && req.pet!.photo!.isNotEmpty;

    // Detect Service Type
    final isWalk =
        req.serviceType == 'walker' ||
        req.serviceName.toLowerCase().contains('walk');
    final isGroom =
        req.serviceType == 'groomer' ||
        req.serviceName.toLowerCase().contains('groom');
    final isTrain =
        req.serviceType == 'trainer' ||
        req.serviceName.toLowerCase().contains('train');
    final isVet =
        req.serviceType == 'vet' ||
        req.serviceName.toLowerCase().contains('consult');
    final isOther = !isWalk && !isGroom && !isTrain && !isVet;

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
      } else if (isOther) {
        pageTitle = _isEnding ? 'END SERVICE' : 'SERVICE IN PROGRESS';
      }
    } else if (req.status == 'upcoming' || req.status == 'confirmed') {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.shade200,
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
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey.shade100,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasPetPhoto
                                ? CachedNetworkImage(
                                    imageUrl: req.pet!.photo!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _buildFallbackAvatar(
                                          req.pet?.name ?? 'P',
                                        ),
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
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
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
                      Builder(
                        builder: (context) {
                          final dateTimeDisplay = req.formattedDateTime;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  'Service',
                                  req.serviceName,
                                  isDark,
                                  Icons.pets_outlined,
                                ),
                                if (!isVet) ...[
                                  _buildDivider(isDark),
                                  _buildDetailRow(
                                    'Type',
                                    'In Person',
                                    isDark,
                                    Icons.location_city_outlined,
                                  ),
                                ],
                                _buildDivider(isDark),
                                _buildDetailRow(
                                  'Date & Time',
                                  dateTimeDisplay,
                                  isDark,
                                  Icons.calendar_month_outlined,
                                ),
                                _buildDivider(isDark),
                                _buildDetailRow(
                                  'Duration',
                                  '${req.durationMinutes} Minutes',
                                  isDark,
                                  Icons.timer_outlined,
                                ),
                                if (req.issues != null &&
                                    req.issues!.isNotEmpty) ...[
                                  _buildDivider(isDark),
                                  _buildDetailRow(
                                    'Issues',
                                    req.issues!,
                                    isDark,
                                    Icons.report_problem_outlined,
                                  ),
                                ],
                                if (req.notes != null &&
                                    req.notes!.isNotEmpty) ...[
                                  _buildDivider(isDark),
                                  _buildDetailRow(
                                    'Owners Note',
                                    req.notes!,
                                    isDark,
                                    Icons.note_alt_outlined,
                                  ),
                                ],
                                _buildDivider(isDark),
                                _buildDetailRowWithMapButton(
                                  'Location',
                                  req.location,
                                  isDark,
                                  Icons.location_on_outlined,
                                  showMap: !isVet,
                                ),
                                if (req.price > 0) ...[
                                  _buildDivider(isDark),
                                  _buildDetailRow(
                                    'Payment',
                                    req.priceDisplay,
                                    isDark,
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // In Progress UI Mocks
                      if (isVet) _buildVetInProgress(isDark),
                      if (isGroom) _buildGroomInProgress(isDark),
                      if (isWalk) _buildWalkInProgress(isDark),
                      if (isTrain) _buildTrainInProgress(isDark),
                      if (isOther) _buildOtherInProgress(isDark),
                    ],
                  ],
                ),
              ),
            ),

            // --- BOTTOM ACTIONS BAR ---
            if (!_inProgress) ...[
              if (req.status == 'pending')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _handleReject(req.id),
                          child: const Text(
                            'REJECT REQUEST',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (req.status == 'upcoming' || req.status == 'confirmed')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _handleStartService(req.id),
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isVet
                                      ? 'START CONSULTATION'
                                      : (isGroom
                                            ? 'START GROOMING'
                                            : (isWalk
                                                  ? 'START WALK'
                                                  : 'START SESSION')),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _handleReject(req.id),
                          child: const Text(
                            'REJECT BOOKING',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Container(
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
                              color: req.status == 'completed'
                                  ? Colors.blue
                                  : AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (req.status == 'completed') ...[
                        writtenReviewsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(
                              color: AppColors.orange,
                            ),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              'Failed to check review status: ${err.toString().replaceFirst('Exception: ', '')}',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          data: (reviewsList) {
                            final hasReviewed = reviewsList.any(
                              (r) => r.bookingId == req.id,
                            );
                            final pastReview = hasReviewed
                                ? reviewsList.firstWhere(
                                    (r) => r.bookingId == req.id,
                                  )
                                : null;

                            if (hasReviewed && pastReview != null) {
                              return Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(0.06),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'YOU RATED CUSTOMER',
                                          style: GoogleFonts.barlow(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.orange,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index < pastReview.rating
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: Colors.amber,
                                              size: 14,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    if (pastReview.comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        pastReview.comment,
                                        style: GoogleFonts.barlow(
                                          fontSize: 12.5,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showRateCustomerDialog(context, req.id),
                                  child: Text(
                                    'RATE CUSTOMER',
                                    style: GoogleFonts.barlow(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
            ] else ...[
              if (isGroom)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
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
                              side: const BorderSide(
                                color: AppColors.orange,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'MESSAGE',
                              style: TextStyle(color: AppColors.orange),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (isTrain)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                          : Text(
                              _isEnding
                                  ? 'COMPLETE SESSION'
                                  : 'COMPLETE SESSION',
                            ),
                    ),
                  ),
                ),
              if (isVet)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleCompleteVet,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE NOTES'),
                    ),
                  ),
                ),
              if (isOther)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (_isEnding) {
                                _handleCompleteOther();
                              } else {
                                setState(() {
                                  _isEnding = true;
                                });
                              }
                            },
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEnding ? 'COMPLETE SERVICE' : 'END SERVICE',
                            ),
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

  Widget _buildOtherInProgress(bool isDark) {
    if (_isEnding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Summary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherSummaryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Provide details about the session...',
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
                ..._otherPhotos.map((file) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () async {
                    final file =
                        await ImagePickerHelper.pickImageWithPermission(
                          context: context,
                          source: ImageSource.gallery,
                        );
                    if (file != null) {
                      setState(() {
                        _otherPhotos.add(File(file.path));
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
      children: [
        Center(
          child: Text(
            _formatDuration(_elapsedSeconds),
            style: GoogleFonts.barlow(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
        ),
        const Center(
          child: Text('Time Elapsed', style: TextStyle(color: AppColors.grey)),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duration', style: TextStyle(color: AppColors.grey)),
                Text(
                  '${widget.request.durationMinutes} minutes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Start Time',
                  style: TextStyle(color: AppColors.grey),
                ),
                Text(
                  widget.request.time.split(',').last.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Service Status',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Active',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                  Row(
                    children: const [
                      Text(
                        'Clinical Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _clinicalNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Observed mild dehydration and gastric symptoms (Required)...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Text(
                        'Diagnostics',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _diagnosticsController,
                    decoration: const InputDecoration(
                      hintText: 'Acute gastric (Required)...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Text(
                        'Treatments',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _treatmentsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'ORS for hydration. Light diet recommended (Required)...',
                    ),
                  ),
                ],
              ),

              // Prescriptions Tab
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Consultation Summary',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _consultSummaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Pet showed improvement, advised to continue medication (Required)...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Follow-up Required?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _followUpRequired,
                          activeColor: AppColors.orange,
                          onChanged: (val) =>
                              setState(() => _followUpRequired = val),
                        ),
                      ],
                    ),
                    if (_followUpRequired) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 2),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (selected != null) {
                            setState(() => _followUpDate = selected);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _followUpDate == null
                                    ? 'Select Date'
                                    : _followUpDate!
                                          .toLocal()
                                          .toString()
                                          .split(' ')
                                          .first,
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chats Tab (Placeholder)
              const Center(
                child: Text('Consultation Chat logs will display here.'),
              ),
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
        Row(
          children: const [
            Text(
              'Service Summary',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _groomingSummaryController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Full Grooming Completed. Buddy is clean. Nail is trimmed (Required)...',
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
          Row(
            children: const [
              Text(
                'Walk Summary',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _walkSummaryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Buddy was friendly and enjoyed the walk (Required)...',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Text(
                'Pet Mood',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
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
            style: GoogleFonts.barlow(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
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
                Text(
                  '${widget.request.durationMinutes} minutes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Start Time',
                  style: TextStyle(color: AppColors.grey),
                ),
                Text(
                  widget.request.time.split(',').last.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Location',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Active',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add, color: AppColors.orange),
          label: const Text(
            'Add File',
            style: TextStyle(color: AppColors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildTrainInProgress(bool isDark) {
    if (_isEnding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Session Summary',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _trainingSummaryController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Great Session! Buddy showed good improvement in focus (Required)...',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Text(
                'Assign Exercise to Pet\'s Parent',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _trainingExerciseController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  '• Regular Practice of sit and stay\n• Loose leash walks (Required, 1 per line)...',
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
            style: GoogleFonts.barlow(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
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
        Row(
          children: const [
            Text(
              'Session Notes',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _trainingNotesController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText:
                'Buddy is responding well to positive reinforcement (Required)...',
          ),
        ),
      ],
    );
  }

  // --- DETAIL ROW BUILDERS ---
  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.barlow(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithMapButton(
    String label,
    String value,
    bool isDark,
    IconData icon, {
    required bool showMap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.barlow(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

  void _showRateCustomerDialog(BuildContext context, String bookingId) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDarkDialog = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDarkDialog
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Rate Customer',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.bold,
                  color: isDarkDialog ? Colors.white : Colors.black87,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How was your experience working with this customer?',
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedRating = starValue;
                            });
                          },
                          child: Icon(
                            starValue <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: commentController,
                      style: GoogleFonts.barlow(
                        color: isDarkDialog ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Share feedback (e.g. friendly customer, pets behaved well)...',
                        hintStyle: GoogleFonts.barlow(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: isDarkDialog
                            ? const Color(0xFF2E2E2E)
                            : const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Feedback is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.barlow(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final comment = commentController.text.trim();
                      Navigator.pop(ctx);
                      _submitCustomerReview(bookingId, selectedRating, comment);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'SUBMIT',
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitCustomerReview(
    String bookingId,
    int rating,
    String comment,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Text('Submitting feedback...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    final success = await ref
        .read(writtenReviewsProvider.notifier)
        .submitCustomerReview(
          bookingId: bookingId,
          rating: rating,
          comment: comment,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer reviewed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to review customer. You may have already reviewed them.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.8,
      size.width - 40,
      size.height * 0.3,
    );
    canvas.drawPath(path, pathPaint);

    final dotPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.3), 6, dotPaint);

    final pulsePaint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width - 40, size.height * 0.3),
      12,
      pulsePaint,
    );

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
