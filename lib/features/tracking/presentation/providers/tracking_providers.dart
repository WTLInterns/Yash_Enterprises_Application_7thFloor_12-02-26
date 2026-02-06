import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasource/tracking_api.dart';
import '../../data/repository/tracking_repository.dart';

final trackingApiProvider = Provider<TrackingApi>((ref) {
  return TrackingApi(ref.watch(dioProvider));
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(
    api: ref.watch(trackingApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  );
});
