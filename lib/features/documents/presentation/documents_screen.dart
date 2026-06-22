import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final int customerId;

  const DocumentsScreen({super.key, required this.customerId});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _loadingCases = false;
  bool _loadingDocs = false;
  String? _error;

  List<Map<String, dynamic>> _cases = const [];
  int? _selectedCaseId;
  List<Map<String, dynamic>> _docs = const [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _loadingCases = true;
      _error = null;
      _cases = const [];
      _selectedCaseId = null;
      _docs = const [];
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/cases/client/${widget.customerId}');
      final data = res.data;

      final list = data is List ? data : <dynamic>[];
      setState(() {
        _cases = list
            .map(
              (e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
            )
            .where((m) => m.isNotEmpty)
            .toList();
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to load cases';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cases';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingCases = false;
        });
      }
    }
  }

  Future<void> _selectCase(int caseId) async {
    setState(() {
      _selectedCaseId = caseId;
      _docs = const [];
      _loadingDocs = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/case-documents/case/$caseId');
      final data = res.data;

      final list = data is List ? data : <dynamic>[];
      setState(() {
        _docs = list
            .map(
              (e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
            )
            .where((m) => m.isNotEmpty)
            .toList();
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'Failed to load documents';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load documents';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDocs = false;
        });
      }
    }
  }

  String _caseTitle(Map<String, dynamic> c) {
    final title = c['title']?.toString().trim();
    final caseNumber = c['caseNumber']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    if (caseNumber != null && caseNumber.isNotEmpty) return caseNumber;
    final id = c['id'];
    return id != null ? 'Case #$id' : 'Case';
  }

  String _docName(Map<String, dynamic> d) {
    final name = d['documentName']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Document';
  }

  String _fileName(Map<String, dynamic> d) {
    final name = d['fileName']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return '';
  }

  int? _docId(Map<String, dynamic> d) {
    final v = d['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: RefreshIndicator(
        onRefresh: _loadCases,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'Cases',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            if (_loadingCases)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_cases.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No cases found.'),
              )
            else
              ..._cases.map((c) {
                final idRaw = c['id'];
                final caseId = idRaw is int
                    ? idRaw
                    : (idRaw is num
                          ? idRaw.toInt()
                          : int.tryParse(idRaw?.toString() ?? ''));

                final isSelected = caseId != null && caseId == _selectedCaseId;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: ListTile(
                    title: Text(_caseTitle(c)),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.chevron_right,
                      color: isSelected ? cs.primary : Colors.grey,
                    ),
                    onTap: caseId == null ? null : () => _selectCase(caseId),
                  ),
                );
              }),

            const SizedBox(height: 16),

            if (_selectedCaseId != null) ...[
              Text(
                'Documents (Case #$_selectedCaseId)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              if (_loadingDocs)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('No documents for this case.'),
                )
              else
                ..._docs.map((d) {
                  final id = _docId(d);
                  final viewUrl =
                      '${AppConfig.apiBaseUrl}/api/case-documents/view/$id';
                  final downloadUrl =
                      '${AppConfig.apiBaseUrl}/api/case-documents/download/$id';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      title: Text(_docName(d)),
                      subtitle: Text(_fileName(d)),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            icon: const Icon(Icons.visibility_outlined),
                            onPressed: id == null
                                ? null
                                : () => _openUrl(viewUrl),
                          ),
                          IconButton(
                            tooltip: 'Download',
                            icon: const Icon(Icons.download_outlined),
                            onPressed: id == null
                                ? null
                                : () => _openUrl(downloadUrl),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
