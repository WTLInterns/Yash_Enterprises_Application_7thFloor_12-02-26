import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasource/auth_api.dart';
import '../../data/repository/auth_repository_impl.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});
