import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePickerHelper {
  static Future<XFile?> pickImageWithPermission({
    required BuildContext context,
    required ImageSource source,
  }) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final picker = ImagePicker();
        return await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 800,
        );
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(
            context,
            'Camera Permission Required',
            'Please enable camera access in your device settings to take a photo.',
          );
        }
        return null;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Camera permission denied.',
                style: GoogleFonts.barlow(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }
    } else {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        final picker = ImagePicker();
        return await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 800,
        );
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(
            context,
            'Photo Library Permission Required',
            'Please enable photo library access in your device settings to select an image.',
          );
        }
        return null;
      } else {
        try {
          final picker = ImagePicker();
          return await picker.pickImage(
            source: source,
            imageQuality: 80,
            maxWidth: 800,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Photo library permission denied.',
                  style: GoogleFonts.barlow(),
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return null;
        }
      }
    }
  }

  static void _showSettingsDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.barlow(fontWeight: FontWeight.w700),
        ),
        content: Text(content, style: GoogleFonts.barlow()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.barlow(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: Text(
              'Settings',
              style: GoogleFonts.barlow(color: const Color(0xFFE85D04)),
            ),
          ),
        ],
      ),
    );
  }

  static Future<ImageSource?> showSourceBottomSheet(
    BuildContext context,
  ) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SELECT IMAGE SOURCE',
                style: GoogleFonts.barlow(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D04).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFE85D04),
                  ),
                ),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Use camera to capture image',
                  style: GoogleFonts.barlow(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D04).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFE85D04),
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Select an image from library',
                  style: GoogleFonts.barlow(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static ImageProvider getImageProvider(String imagePathOrUrl) {
    final cleanedPath = imagePathOrUrl.trim();
    if (cleanedPath.isEmpty) {
      return const AssetImage('android/assets/ProfileSetUp.png');
    }

    if (cleanedPath.startsWith('data:image') ||
        cleanedPath.contains(';base64,')) {
      try {
        final base64String = cleanedPath.split(',').last;
        final bytes = base64.decode(base64String.trim());
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error parsing base64 data URL: $e');
        return const AssetImage('android/assets/ProfileSetUp.png');
      }
    }

    if (!cleanedPath.startsWith('http') &&
        !cleanedPath.startsWith('/') &&
        !cleanedPath.contains('\\') &&
        cleanedPath.length > 50) {
      try {
        final bytes = base64.decode(cleanedPath);
        return MemoryImage(bytes);
      } catch (_) {}
    }

    final uri = Uri.tryParse(cleanedPath);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority) {
      return CachedNetworkImageProvider(cleanedPath);
    }
    try {
      final file = File(cleanedPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    return const AssetImage('android/assets/ProfileSetUp.png');
  }
}
