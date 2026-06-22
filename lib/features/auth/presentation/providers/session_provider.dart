import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';

/// Session state - SINGLE SOURCE OF TRUTH for authentication
class SessionController extends ChangeNotifier {
  SessionController(this._ref);

  final Ref _ref;

  // In-memory auth state (primary source of truth)
  String? _token;
  String? _employeeId;
  String? _name;
  String? _role;
  String? _department; // 🚨 ADD MISSING DEPARTMENT FIELD
  
  bool _initialized = false;

  // Getters
  bool get isLoggedIn => _employeeId != null && _employeeId!.isNotEmpty;
  bool get initialized => _initialized;
  String? get token => _token;
  String? get employeeId => _employeeId;
  String? get name => _name;
  String? get role => _role;
  String? get department => _department; // 🚨 ADD MISSING DEPARTMENT GETTER

  /// Initialize session from storage on app start ONLY
  Future<void> init() async {
    final storage = _ref.read(secureSessionStorageProvider);
    _token = await storage.readToken();
    _employeeId = await storage.readEmployeeId();
    _name = await storage.readName();
    _role = await storage.readRole();
    _department = await storage.readUserDepartment(); // 🚨 ADD MISSING DEPARTMENT INIT
    _initialized = true;
    
    print('===== SESSION INIT FROM STORAGE =====');
    print('isLoggedIn: $isLoggedIn');
    print('employeeId: "$_employeeId"');
    print('role: "$_role"');
    print('department: "$_department"'); // 🚨 LOG DEPARTMENT
    notifyListeners();
  }

  /// Set session immediately after login (synchronous state update)
  void setSession({
    String? token,
    required String employeeId,
    required String name,
    required String role,
    required String? department, // 🚨 ADD MISSING DEPARTMENT PARAMETER
  }) {
    _token = token;
    _employeeId = employeeId;
    _name = name;
    _role = role;
    _department = department; // 🚨 SET DEPARTMENT IN MEMORY
    
    print('===== SESSION SET IN MEMORY =====');
    print('isLoggedIn: $isLoggedIn');
    print('employeeId: "$_employeeId"');
    print('role: "$_role"');
    print('department: "$_department"'); // 🚨 LOG DEPARTMENT
    notifyListeners(); // Triggers router redirect immediately
  }

  /// Clear session on logout
  Future<void> logout() async {
    _token = null;
    _employeeId = null;
    _name = null;
    _role = null;
    _department = null; // 🚨 CLEAR DEPARTMENT
    
    await _ref.read(secureSessionStorageProvider).clear();
    print('✅ SESSION CLEARED');
    notifyListeners();
  }
}

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final c = SessionController(ref);
  c.init(); // Load from storage on app start
  return c;
});
