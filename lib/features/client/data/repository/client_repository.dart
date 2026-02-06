import '../datasource/client_api.dart';

class ClientRepository {
  ClientRepository({required ClientApi api}) : _api = api;

  final ClientApi _api;

  Future<List<dynamic>> getClients() => _api.listClients();
  Future<List<dynamic>> getSites() => _api.listSites();
  Future<Map<String, dynamic>> getClient(int id) => _api.getClient(id);
  Future<void> createClient(Map<String, dynamic> payload) => _api.createClient(payload);
  Future<void> updateClient(int id, Map<String, dynamic> payload) => _api.updateClient(id, payload);
  Future<void> deleteClient(int id) => _api.deleteClient(id);
}
