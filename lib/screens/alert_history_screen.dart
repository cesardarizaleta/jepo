import 'package:flutter/material.dart';

import '../models/incident_alert.dart';
import '../services/api_client.dart';
import '../services/metrics_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/neumorphic_container.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final MetricsService _metrics = MetricsService(appApi);
  final ScrollController _scrollController = ScrollController();

  AlertMetrics _metricsData = AlertMetrics.empty;
  final List<IncidentAlert> _alerts = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;

  AlertStatus? _filterEstado;
  DateTime? _filterDesde;
  DateTime? _filterHasta;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAll(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadHistorial(refresh: false);
    }
  }

  Future<void> _loadAll({required bool refresh}) async {
    if (refresh) {
      setState(() => _loading = true);
    }
    try {
      final metricsFuture = _metrics.getMetrics();
      if (refresh) {
        _currentPage = 1;
        _alerts.clear();
      }
      final historialFuture = _loadHistorial(refresh: refresh, silent: true);
      final metrics = await metricsFuture;
      await historialFuture;
      if (mounted) {
        setState(() => _metricsData = metrics);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error al cargar datos: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistorial({
    required bool refresh,
    bool silent = false,
  }) async {
    if (_loadingMore) return;
    if (!refresh && !_hasMore) return;

    if (!silent) {
      setState(() {
        if (refresh) {
          _loading = true;
        } else {
          _loadingMore = true;
        }
      });
    } else if (!refresh) {
      setState(() => _loadingMore = true);
    }

    try {
      final page = refresh ? 1 : _currentPage + 1;
      final result = await _metrics.getHistorial(
        pagina: page,
        estado: _filterEstado?.apiValue,
        desde: _filterDesde,
        hasta: _filterHasta,
      );

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _alerts
            ..clear()
            ..addAll(result.data);
        } else {
          _alerts.addAll(result.data);
        }
        _currentPage = result.pagina;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (mounted && !silent) {
        AppToast.error(context, 'Error al cargar historial: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _showFilters() async {
    AlertStatus? estado = _filterEstado;
    DateTime? desde = _filterDesde;
    DateTime? hasta = _filterHasta;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AlertStatus?>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...AlertStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => estado = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: desde ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => desde = picked);
                            }
                          },
                          child: Text(
                            desde == null
                                ? 'Desde'
                                : _formatDate(desde!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: hasta ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => hasta = picked);
                            }
                          },
                          child: Text(
                            hasta == null ? 'Hasta' : _formatDate(hasta!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              estado = null;
                              desde = null;
                              hasta = null;
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _filterEstado = estado;
        _filterDesde = desde;
        _filterHasta = hasta;
      });
      await _loadAll(refresh: true);
    }
  }

  Future<void> _showResolveDialog(IncidentAlert alert) async {
    final notasController = TextEditingController();
    AlertStatus? selected;

    final resolved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              title: const Text('Resolver alerta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Clasifica esta alerta para mejorar las métricas del sistema.',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 16),
                  _ResolveOption(
                    label: 'Alerta real',
                    icon: Icons.warning_amber_rounded,
                    color: AlertStatus.real.color,
                    selected: selected == AlertStatus.real,
                    onTap: () =>
                        setDialogState(() => selected = AlertStatus.real),
                  ),
                  const SizedBox(height: 8),
                  _ResolveOption(
                    label: 'Falso positivo',
                    icon: Icons.block_outlined,
                    color: AlertStatus.falsoPositivo.color,
                    selected: selected == AlertStatus.falsoPositivo,
                    onTap: () => setDialogState(
                      () => selected = AlertStatus.falsoPositivo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notasController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resolved != true || selected == null || alert.id == null) {
      notasController.dispose();
      return;
    }

    try {
      await _metrics.resolveAlert(
        alert.id!,
        selected!,
        notas: notasController.text.trim().isEmpty
            ? null
            : notasController.text.trim(),
      );
      notasController.dispose();
      if (mounted) {
        AppToast.success(context, 'Alerta resuelta correctamente');
        await _loadAll(refresh: true);
      }
    } catch (e) {
      notasController.dispose();
      if (mounted) {
        AppToast.error(context, 'No se pudo resolver: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Historial y Métricas',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _loading && _alerts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => _loadAll(refresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildMetricsSection()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Historial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_metricsData.totalAlertas} alertas',
                            style: const TextStyle(color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_alerts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No hay alertas para mostrar',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= _alerts.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            }
                            return _buildAlertTile(_alerts[index]);
                          },
                          childCount:
                              _alerts.length + (_loadingMore ? 1 : 0),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total',
                  value: '${_metricsData.totalAlertas}',
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Reales',
                  value: '${_metricsData.alertasReales}',
                  color: AlertStatus.real.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Falsos +',
                  value: '${_metricsData.falsosPositivos}',
                  color: AlertStatus.falsoPositivo.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Tasa FP',
                  value:
                      '${_metricsData.tasaFalsosPositivos.toStringAsFixed(1)}%',
                  color: AlertStatus.falsoPositivo.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: NeumorphicContainer(
                  useAnimation: false,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alertas por mes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: _MonthlyBarChart(
                          data: _metricsData.alertasPorMes,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              NeumorphicContainer(
                useAnimation: false,
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _AccuracyRingPainter(
                      accuracy: _metricsData.tasaAlertasReales,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_metricsData.tasaAlertasReales.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Text(
                            'Precisión',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(IncidentAlert alert) {
    final isPending = alert.estado == AlertStatus.pendiente;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicButton(
        onPressed: isPending ? () => _showResolveDialog(alert) : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: alert.estado.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(alert.estado.icon, color: alert.estado.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateTime(alert.fechaHora),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.esProactiva ? 'Proactiva' : 'Manual',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: alert.estado),
            if (isPending) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.textLight,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    return '${_pad(local.day)}/${_pad(local.month)}/${local.year} '
        '${_pad(local.hour)}:${_pad(local.minute)}';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${_pad(local.day)}/${_pad(local.month)}/${local.year}';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      useAnimation: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AlertStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _ResolveOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ResolveOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.textLight.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          color: selected ? color.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<AlertMonthlyStats> data;

  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos mensuales',
          style: TextStyle(color: AppTheme.textLight, fontSize: 12),
        ),
      );
    }

    final display = data.length > 6 ? data.sublist(data.length - 6) : data;

    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _MonthlyBarChartPainter(months: display),
    );
  }
}

class _MonthlyBarChartPainter extends CustomPainter {
  final List<AlertMonthlyStats> months;

  _MonthlyBarChartPainter({required this.months});

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final maxVal = months
        .map((m) => m.reales + m.falsosPositivos)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 999);

    final barGroupWidth = size.width / months.length;
    const bottomPad = 22.0;
    final chartHeight = size.height - bottomPad;

    final realPaint = Paint()..color = AlertStatus.real.color;
    final fpPaint = Paint()..color = AlertStatus.falsoPositivo.color;
    final labelStyle = const TextStyle(fontSize: 9, color: AppTheme.textLight);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final groupCenter = barGroupWidth * i + barGroupWidth / 2;
      const barWidth = 10.0;
      final gap = 2.0;

      final realH = (month.reales / maxVal) * chartHeight;
      final fpH = (month.falsosPositivos / maxVal) * chartHeight;

      final realLeft = groupCenter - barWidth - gap / 2;
      final fpLeft = groupCenter + gap / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(realLeft, chartHeight - realH, barWidth, realH),
          const Radius.circular(3),
        ),
        realPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(fpLeft, chartHeight - fpH, barWidth, fpH),
          const Radius.circular(3),
        ),
        fpPaint,
      );

      final label = month.mes.length >= 7
          ? month.mes.substring(5)
          : month.mes;
      textPainter.text = TextSpan(text: label, style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenter - textPainter.width / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.months != months;
  }
}

class _AccuracyRingPainter extends CustomPainter {
  final double accuracy;

  _AccuracyRingPainter({required this.accuracy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const stroke = 8.0;

    final bgPaint = Paint()
      ..color = AppTheme.textLight.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweep = (accuracy.clamp(0, 100) / 100) * 2 * 3.14159265;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AccuracyRingPainter oldDelegate) {
    return oldDelegate.accuracy != accuracy;
  }
}
