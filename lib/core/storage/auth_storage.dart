import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static Future<int> getEmployeeId() async {
    const storage = FlutterSecureStorage();
    final employeeId = await storage.read(key: 'employee_id');
    return int.tryParse(employeeId ?? '0') ?? 0;
  }

  static Future<String> getEmployeeName() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'employee_name') ?? '';
  }

  static Future<String> getEmployeeRole() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'employee_role') ?? '';
  }
}
