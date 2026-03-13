import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class AddressEditRequestScreen extends StatefulWidget {
  final int addressId;
  final String currentAddress;
  final double currentLatitude;
  final double currentLongitude;

  const AddressEditRequestScreen({
    Key? key,
    required this.addressId,
    required this.currentAddress,
    required this.currentLatitude,
    required this.currentLongitude,
  }) : super(key: key);

  @override
  _AddressEditRequestScreenState createState() =>
      _AddressEditRequestScreenState();
}

class _AddressEditRequestScreenState extends State<AddressEditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressLineController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _reasonController;
  final _secureStorage = const FlutterSecureStorage();

  // Address type selection
  String _selectedAddressType = 'PRIMARY';

  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _newLatitude;
  double? _newLongitude;
  String? _requestStatus;

  // 🚀 Google Maps Reverse Geocoding API (Production-safe, Clean)
  Future<void> _reverseGeocodeWithGoogle(double lat, double lng) async {
    const apiKey = String.fromEnvironment('GOOGLE_MAPS_KEY');

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&language=en'
      '&key=$apiKey',
    );

    try {
      final res = await http.get(url);

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      if (data['status'] != 'OK' || data['results'].isEmpty) return;

      final result = data['results'][0];
      final components = result['address_components'] as List;

      String get(String type) {
        return components.firstWhere(
              (c) => (c['types'] as List).contains(type),
              orElse: () => null,
            )?['long_name'] ??
            '';
      }

      final premise = get('premise');
      final route = get('route');
      final subLocality = get('sublocality_level_1');
      final locality = get('locality');

      setState(() {
        // ✅ CLEAN ADDRESS LINE (short, no duplicates)
        _addressLineController.text = [
          premise,
          route,
          subLocality,
          locality,
        ].where((e) => e.isNotEmpty).take(2).join(', ');

        _cityController.text = locality.isNotEmpty
            ? locality
            : get('administrative_area_level_2');
        _stateController.text = get('administrative_area_level_1');
        _pincodeController.text = get('postal_code');
        _countryController.text = get('country');
      });
    } catch (e) {
      debugPrint('Google reverse geocoding failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with widget values to prevent initialValue/controller conflict
    _addressLineController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _countryController = TextEditingController(text: 'India');
    _reasonController = TextEditingController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _newLatitude = position.latitude;
        _newLongitude = position.longitude;
      });

      // 🔥 REVERSE GEOCODING - Auto-fill address fields
      try {
        // Use Google Maps API instead of Android geocoder
        await _reverseGeocodeWithGoogle(position.latitude, position.longitude);
      } catch (e) {
        // If Google API fails, at least we have coordinates
        print('Reverse geocoding failed: $e');
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch location: $e')));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newLatitude == null || _newLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location capture')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get employee ID from secure storage
      final employeeId = await _secureStorage.read(key: 'employee_id');
      if (employeeId == null) {
        throw Exception('Employee ID not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/api/customer-address-edit-requests?employeeId=$employeeId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'addressId': widget.addressId,
          'addressType': _selectedAddressType,
          'newAddressLine': _addressLineController.text.trim(),
          'newCity': _cityController.text.trim(),
          'newState': _stateController.text.trim(),
          'newPincode': _pincodeController.text.trim(),
          'newCountry': _countryController.text.trim(),
          'newLatitude': _newLatitude,
          'newLongitude': _newLongitude,
          'reason': _reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _requestStatus = 'PENDING');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto-refresh after 30 seconds
        _refreshStatus();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit request');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    // Implement status checking logic here
    // You can call GET /api/customer-address-edit-requests/{requestId}
  }

  @override
  Widget build(BuildContext context) {
    if (_requestStatus == 'PENDING') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Address Update Request'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pending, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Request Pending Approval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Admin will review your request shortly',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Address Update'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Address Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.currentAddress),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${widget.currentLatitude}, Lng: ${widget.currentLongitude}',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // New Address Form
              const Text(
                'Proposed New Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(
                  labelText: 'Address Line',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address line';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Address Type Selection
              DropdownButtonFormField<String>(
                value: _selectedAddressType,
                decoration: const InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city, color: Colors.grey),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PRIMARY',
                    child: Text('Primary Address'),
                  ),
                  DropdownMenuItem(
                    value: 'POLICE',
                    child: Text('Police Address'),
                  ),
                  DropdownMenuItem(
                    value: 'POST',
                    child: Text('Post Office Address'),
                  ),
                  DropdownMenuItem(
                    value: 'TAHSIL',
                    child: Text('Tahsil Address'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAddressType = value!);
                  }
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location Capture
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          const Text(
                            'Current GPS Location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_isGettingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton(
                              onPressed: _getCurrentLocation,
                              child: const Text('Refresh'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_newLatitude != null && _newLongitude != null)
                        Text(
                          'Lat: ${_newLatitude!.toStringAsFixed(6)}, Lng: ${_newLongitude!.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.green),
                        )
                      else
                        const Text(
                          'Getting location...',
                          style: TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Change',
                  border: OutlineInputBorder(),
                  hintText:
                      'e.g., Client shifted to new location, Address correction needed...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide reason for address change';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
