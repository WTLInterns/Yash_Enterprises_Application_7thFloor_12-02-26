import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_session_storage.dart';
import 'raw_key_value_storage.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureSessionStorageProvider = Provider<SecureSessionStorage>((ref) {
  return SecureSessionStorage(ref.watch(flutterSecureStorageProvider));
});

final rawKeyValueStorageProvider = Provider<RawKeyValueStorage>((ref) {
  return RawKeyValueStorage(ref.watch(flutterSecureStorageProvider));
});
