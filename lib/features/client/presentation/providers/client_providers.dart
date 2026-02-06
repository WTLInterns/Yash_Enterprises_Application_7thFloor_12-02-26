import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasource/client_api.dart';
import '../../data/repository/client_repository.dart';

final clientApiProvider = Provider<ClientApi>((ref) {
  return ClientApi(ref.watch(dioProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(api: ref.watch(clientApiProvider));
});

final clientsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(clientRepositoryProvider).getClients();
});

final sitesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(clientRepositoryProvider).getSites();
});
