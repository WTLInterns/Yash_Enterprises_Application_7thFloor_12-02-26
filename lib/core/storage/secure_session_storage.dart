import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token';
  static const _kEmployeeId = 'employee_id';
  static const _kName = 'employee_name';
  static const _kRole = 'employee_role';
  static const _kProfileImage = 'employee_profile_image';

  static const _kEmployeeIdLegacy = 'employeeId';
  static const _kNameLegacy = 'employeeName';
  static const _kRoleLegacy = 'employeeRole';

  Future<void> saveSession({
    required String token,
    required String employeeId,
    required String name,
    required String role,
    required String? profileImage,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kEmployeeId, value: employeeId);
    await _storage.write(key: _kName, value: name);
    await _storage.write(key: _kRole, value: role);
    await _storage.write(key: _kProfileImage, value: profileImage);

    await _storage.write(key: _kEmployeeIdLegacy, value: employeeId);
    await _storage.write(key: _kNameLegacy, value: name);
    await _storage.write(key: _kRoleLegacy, value: role);
  }

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readEmployeeId() => _storage.read(key: _kEmployeeId);
  Future<String?> readName() => _storage.read(key: _kName);
  Future<String?> readRole() => _storage.read(key: _kRole);
  Future<String?> readProfileImage() => _storage.read(key: _kProfileImage);

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kEmployeeId);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kRole);
    await _storage.delete(key: _kProfileImage);

    await _storage.delete(key: _kEmployeeIdLegacy);
    await _storage.delete(key: _kNameLegacy);
    await _storage.delete(key: _kRoleLegacy);
  }
}
