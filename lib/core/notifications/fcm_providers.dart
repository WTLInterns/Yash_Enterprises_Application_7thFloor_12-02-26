import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/storage_providers.dart';
import 'fcm_token_sync.dart';

final fcmTokenSyncProvider = Provider<FcmTokenSync>((ref) {
  return FcmTokenSync(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});
