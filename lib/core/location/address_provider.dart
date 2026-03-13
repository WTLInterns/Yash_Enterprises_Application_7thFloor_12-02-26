import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final currentAddressProvider = FutureProvider<String?>((ref) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );

    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final parts =
        <String?>[p.street, p.subLocality, p.locality, p.administrativeArea]
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
});
