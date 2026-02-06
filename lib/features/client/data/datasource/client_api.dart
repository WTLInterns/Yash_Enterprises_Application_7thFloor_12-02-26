import 'package:dio/dio.dart';

class ClientApi {
  ClientApi(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listClients() async {
    final res = await _dio.get('/clients');
    return (res.data as List).cast();
  }

  Future<List<dynamic>> listSites() async {
    // Backend exposes sites at GET /api/sites
    final res = await _dio.get('/sites');
    return (res.data as List).cast();
  }

  Future<Map<String, dynamic>> getClient(int id) async {
    final res = await _dio.get('/clients/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> createClient(Map<String, dynamic> payload) async {
    await _dio.post('/clients', data: payload);
  }

  Future<void> updateClient(int id, Map<String, dynamic> payload) async {
    await _dio.put('/clients/$id', data: payload);
  }

  Future<void> deleteClient(int id) async {
    await _dio.delete('/clients/$id');
  }
}
