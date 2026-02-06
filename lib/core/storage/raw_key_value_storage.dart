import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RawKeyValueStorage {
  RawKeyValueStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? '1' : '0');
  }

  Future<bool?> readBool(String key) async {
    final v = await _storage.read(key: key);
    if (v == null) return null;
    return v == '1';
  }
}
