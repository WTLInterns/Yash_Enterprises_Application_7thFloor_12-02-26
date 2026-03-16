import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token';
  static const _kEmployeeId = 'employee_id';
  static const _kName = 'employee_name';
  static const _kRole = 'employee_role';
  static const _kProfileImage = 'employee_profile_image';

  static const _kUserRole = 'user_role';
  static const _kUserDepartment = 'user_department';

  static const _kEmployeeIdLegacy = 'employeeId';
  static const _kNameLegacy = 'employeeName';
  static const _kRoleLegacy = 'employeeRole';

  Future<void> saveSession({
    required String token,
    required String employeeId,
    required String name,
    required String role,
    required String? department,
    required String? profileImage,
  }) async {
    print('===== STORING USER SESSION =====');
    print('Storing employee_id: $employeeId');
    print('Storing user_role: $role');
    print('Storing user_department: $department');

    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kEmployeeId, value: employeeId);
    await _storage.write(key: _kName, value: name);
    await _storage.write(key: _kRole, value: role);
    await _storage.write(key: _kUserRole, value: role);
    await _storage.write(key: _kUserDepartment, value: department);
    await _storage.write(key: _kProfileImage, value: profileImage);

    await _storage.write(key: _kEmployeeIdLegacy, value: employeeId);
    await _storage.write(key: _kNameLegacy, value: name);
    await _storage.write(key: _kRoleLegacy, value: role);

    final storedEmployeeId = await _storage.read(key: _kEmployeeId);
    final storedRole = await _storage.read(key: _kUserRole);
    final storedDepartment = await _storage.read(key: _kUserDepartment);

    print('===== STORED SESSION DATA =====');
    print('Stored employee_id: $storedEmployeeId');
    print('Stored role: $storedRole');
    print('Stored department: $storedDepartment');
  }

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readEmployeeId() => _storage.read(key: _kEmployeeId);
  Future<String?> readName() => _storage.read(key: _kName);
  Future<String?> readRole() => _storage.read(key: _kRole);
  Future<String?> readUserRole() => _storage.read(key: _kUserRole);
  Future<String?> readUserDepartment() => _storage.read(key: _kUserDepartment);
  Future<String?> readProfileImage() => _storage.read(key: _kProfileImage);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kEmployeeId);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kRole);
    await _storage.delete(key: _kUserRole);
    await _storage.delete(key: _kUserDepartment);
    await _storage.delete(key: _kProfileImage);

    await _storage.delete(key: _kEmployeeIdLegacy);
    await _storage.delete(key: _kNameLegacy);
    await _storage.delete(key: _kRoleLegacy);
  }
}
