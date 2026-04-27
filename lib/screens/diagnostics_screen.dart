import 'package:flutter/material.dart';
import '../services/alert_queue_service.dart';
import '../services/api_client.dart';
import '../services/diagnostic_log_service.dart';
import '../services/pre_alert_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<DiagnosticEntry> _entries = [];
  bool _loading = true;
  int _pendingCount = 0;
  bool _incidentActive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final entries = await DiagnosticLogService.getEntries();
      final pending = appApiInitialized
          ? await AlertQueueService(appApi).pendingCount()
          : 0;
      final incident = PreAlertService.isIncidentActive;
      if (mounted) {
        setState(() {
          _entries = entries;
          _pendingCount = pending;
          _incidentActive = incident;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('DiagnosticsScreen load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearLog() async {
    await DiagnosticLogService.clear();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Diagnósticos',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppTheme.textLight),
            onPressed: _clearLog,
            tooltip: 'Limpiar registro',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status summary cards
                  _buildStatusRow(),
                  const SizedBox(height: 20),

                  // Event log
                  const Text(
                    'REGISTRO DE EVENTOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Aún no hay eventos de diagnóstico registrados.',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ),
                    )
                  else
                    ..._entries.take(100).map(_buildEntryCard),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            label: 'Cola',
            value: '$_pendingCount',
            icon: Icons.queue,
            color: _pendingCount > 0
                ? Colors.orange
                : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            label: 'Incidente',
            value: _incidentActive ? 'ACTIVO' : 'Ninguno',
            icon: Icons.warning_amber_rounded,
            color: _incidentActive ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            label: 'Eventos',
            value: '${_entries.length}',
            icon: Icons.list_alt,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(DiagnosticEntry entry) {
    final severityColor = _severityColor(entry.severity);
    final categoryIcon = _categoryIcon(entry.category);
    final timeStr = _formatTime(entry.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity dot + category icon
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(categoryIcon, size: 18, color: AppTheme.textLight),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.category}.${entry.event}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  if (entry.detail != null && entry.detail!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.detail!,
                        style: TextStyle(
                          fontSize: 12,
                          color: severityColor == Colors.red
                              ? Colors.red.shade700
                              : AppTheme.textLight,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (entry.eventId != null && entry.eventId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'eid: ${entry.eventId}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'queue':
        return Icons.queue;
      case 'session':
        return Icons.vpn_key;
      case 'incident':
        return Icons.warning;
      case 'api':
        return Icons.cloud;
      case 'background':
        return Icons.settings;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}'
        ':${local.minute.toString().padLeft(2, '0')}'
        ':${local.second.toString().padLeft(2, '0')}';
  }
}
