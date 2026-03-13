import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yashenterprisesapp/features/address/presentation/address_edit_request_screen.dart';

Widget _buildAddressEditButton({
  required double? distanceToCustomer,
  required Map<String, dynamic>? task,
  required BuildContext context,
}) {
  // Only show when outside geofence
  if (distanceToCustomer != null && distanceToCustomer <= 200) {
    return const SizedBox.shrink(); // Don't show if inside geofence
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ElevatedButton.icon(
      onPressed: () {
        if (task?['customerAddressId'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No customer address assigned')),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddressEditRequestScreen(
              addressId: task?['customerAddressId'],
              currentAddress: _formatCustomerAddress(task),
              currentLatitude: task?['customerAddress']?['latitude'] ?? 0.0,
              currentLongitude: task?['customerAddress']?['longitude'] ?? 0.0,
            ),
          ),
        );
      },
      icon: const Icon(Icons.edit_location),
      label: const Text('Request Address Update'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

String _formatCustomerAddress(Map<String, dynamic>? task) {
  final address = task?['customerAddress'];
  if (address == null) return 'No address';

  final parts = [
    address['addressLine'],
    address['city'],
    address['state'],
    address['pincode'],
  ].where((part) => part != null && (part as String).isNotEmpty);

  return parts.join(', ');
}
