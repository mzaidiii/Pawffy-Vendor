import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Fetches the device's current position, handling permission + service checks.
final positionProvider = FutureProvider.autoDispose<Position>((ref) async {
  // Check if location services are enabled on the device.
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled');
  }

  // Check current permission status.
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission permanently denied');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
});

/// Reverse-geocodes the current position into a readable "City, State" string.
final locationTextProvider = FutureProvider.autoDispose<String>((ref) async {
  final position = await ref.watch(positionProvider.future);

  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  if (placemarks.isEmpty) {
    throw Exception('Could not resolve address');
  }

  final place = placemarks.first;

  final city = place.locality?.isNotEmpty == true
      ? place.locality!
      : (place.subAdministrativeArea ?? '');
  final state = place.administrativeArea ?? '';

  if (city.isEmpty && state.isEmpty) {
    throw Exception('Could not resolve address');
  }

  if (city.isEmpty) return state;
  if (state.isEmpty) return city;

  return '$city, $state';
});
