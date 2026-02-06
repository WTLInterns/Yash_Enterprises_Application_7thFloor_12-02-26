import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._ref);

  final Ref _ref;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init() async {
    final token = await _ref.read(secureSessionStorageProvider).readToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    final token = await _ref.read(secureSessionStorageProvider).readToken();
    final next = token != null && token.isNotEmpty;
    if (next != _isLoggedIn) {
      _isLoggedIn = next;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _ref.read(secureSessionStorageProvider).clear();
    _isLoggedIn = false;
    notifyListeners();
  }
}

final sessionProvider = ChangeNotifierProvider<SessionController>((ref) {
  final c = SessionController(ref);
  // fire and forget init
  c.init();
  return c;
});
