import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasource/client_api.dart';
import '../../data/repository/client_repository.dart';

const bool _assignedClientProviderLogs = true;

void _assignedClientProviderLog(String message) {
  if (!_assignedClientProviderLogs) return;
  print('[AssignedClientProvider] $message');
}

final clientApiProvider = Provider<ClientApi>((ref) {
  return ClientApi(ref.watch(dioProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(api: ref.watch(clientApiProvider));
});

final clientsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(clientRepositoryProvider).getClients();
});

final assignedClientsProvider = FutureProvider<List<dynamic>>((ref) async {
  final storage = ref.watch(secureSessionStorageProvider);
  final employeeIdStr = await storage.readEmployeeId();
  final role =
      (await storage.readUserRole()) ?? (await storage.readRole()) ?? '';

  _assignedClientProviderLog(
    'assignedClientsProvider: employeeIdStr=$employeeIdStr role=$role',
  );

  if (role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'MANAGER') {
    _assignedClientProviderLog(
      'assignedClientsProvider: using global /clients',
    );
    final list = await ref.watch(clientRepositoryProvider).getClients();
    _assignedClientProviderLog(
      'assignedClientsProvider: received length=${list.length}',
    );
    return list;
  }

  final employeeId = int.tryParse(employeeIdStr ?? '');
  if (employeeId == null) {
    _assignedClientProviderLog('assignedClientsProvider: missing employeeId');
    return [];
  }

  _assignedClientProviderLog(
    'assignedClientsProvider: using /clients/assigned',
  );
  final list = await ref
      .watch(clientRepositoryProvider)
      .getAssignedClients(employeeId: employeeId, role: role);
  _assignedClientProviderLog(
    'assignedClientsProvider: received length=${list.length}',
  );
  return list;
});

final sitesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(clientRepositoryProvider).getSites();
});
