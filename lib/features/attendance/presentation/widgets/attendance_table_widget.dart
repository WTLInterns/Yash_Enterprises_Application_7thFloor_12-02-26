import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceTableWidget extends StatelessWidget {
  const AttendanceTableWidget({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  static const double _wDate = 90;
  static const double _wDay = 80;
  static const double _wStatus = 100;
  static const double _wPunchIn = 110;
  static const double _wPunchOut = 110;
  static const double _wTotalHrs = 100;
  static const double _wTotalKm = 100;
  static const double _wAddr = 200;

  static const double _rowH = 44;

  double get _tableWidth =>
      _wDate +
      _wDay +
      _wStatus +
      _wPunchIn +
      _wPunchOut +
      _wTotalHrs +
      _wTotalKm +
      _wAddr +
      _wAddr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                _headerRow(cs),
                const SizedBox(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return _dataRow(context, cs, r, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerRow(ColorScheme cs) {
    return Container(
      height: _rowH,
      color: Colors.grey.shade200,
      child: Row(
        children: [
          _headerCell('Date', _wDate),
          _headerCell('Day', _wDay),
          _headerCell('Status', _wStatus),
          _headerCell('Punch In', _wPunchIn),
          _headerCell('Punch Out', _wPunchOut),
          _headerCell('Total Hrs', _wTotalHrs),
          _headerCell('Total KM', _wTotalKm),
          _headerCell('Punch In Address', _wAddr),
          _headerCell('Punch Out Address', _wAddr),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double w) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _dataRow(
    BuildContext context,
    ColorScheme cs,
    Map<String, dynamic> r,
    int index,
  ) {
    final bg = index.isEven ? Colors.white : const Color(0xFFF7F8FB);

    final date = _parseDate(r['date']);
    final dateText = date != null ? DateFormat('dd-MM-yyyy').format(date) : '-';
    final dayText = date != null ? DateFormat('EEE').format(date) : '-';

    final statusRaw = (r['status']?.toString() ?? '').trim();
    final statusText = _formatStatusText(statusRaw);
    final statusColor = _statusColor(statusRaw);

    final punchInText = _formatTimeHm(r['punchInTime']);
    final punchOutText = _formatTimeHm(r['punchOutTime']);

    final totalHrsText = _formatNumber(r['totalHours']);
    final totalKmText = _formatNumber(r['totalKm']);

    final inAddr = (r['punchInAddress']?.toString() ?? '').trim();
    final outAddr = (r['punchOutAddress']?.toString() ?? '').trim();

    return Container(
      height: _rowH,
      color: bg,
      child: Row(
        children: [
          _cell(dateText, _wDate),
          _cell(dayText, _wDay),
          _statusCell(statusText, statusColor, _wStatus),
          _cell(punchInText, _wPunchIn),
          _cell(punchOutText, _wPunchOut),
          _cell(totalHrsText, _wTotalHrs),
          _cell(totalKmText, _wTotalKm),
          _cell(inAddr.isEmpty ? '-' : inAddr, _wAddr),
          _cell(outAddr.isEmpty ? '-' : outAddr, _wAddr),
        ],
      ),
    );
  }

  Widget _cell(String text, double w) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }

  Widget _statusCell(String text, Color color, double w) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeHm(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString().trim();
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.parse(s);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  String _formatNumber(dynamic raw) {
    if (raw == null) return '-';
    if (raw is num) {
      return raw.toString();
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return '-';
    final n = num.tryParse(s);
    return n?.toString() ?? '-';
  }

  Color _statusColor(String statusRaw) {
    final s = statusRaw.toUpperCase();
    if (s == 'PRESENT') return Colors.green;
    if (s == 'ABSENT') return Colors.red;
    if (s == 'HALF_DAY' || s == 'HALF DAY') return Colors.orange;
    if (s == 'ON_LEAVE') return Colors.orange;
    if (s == 'PENDING') return Colors.grey;
    if (s == 'HOLIDAY') return Colors.amber;
    if (s == 'WEEKLY_OFF') return Colors.blueGrey;
    return Colors.blueGrey;
  }

  String _formatStatusText(String statusRaw) {
    final s = statusRaw.toUpperCase();
    if (s == 'HALF_DAY') return 'Half Day';
    if (s == 'ON_LEAVE') return 'Leave';
    if (s.isEmpty) return '-';
    final lower = s.toLowerCase().replaceAll('_', ' ');
    return lower
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}
