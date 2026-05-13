import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/monitored_user.dart';
import '../providers/monitored_users_provider.dart';
import '../theme/app_theme.dart';

// ─── Palette ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFEEEEEE);
const Color _teal = Color(0xFF26A69A);
const Color _danger = Color(0xFFFF5151);
const Color _textPrimary = Color(0xFF747877);
const Color _shadowDark = Color(0xFFA3B1C6);
const Color _shadowLight = Colors.white;

/// Default view centered on Caracas when we have no known users with a
/// location fix yet.
const LatLng _fallbackCenter = LatLng(10.4806, -66.9036);

class FamilyMapScreen extends ConsumerStatefulWidget {
  const FamilyMapScreen({super.key});

  @override
  ConsumerState<FamilyMapScreen> createState() => _FamilyMapScreenState();
}

class _FamilyMapScreenState extends ConsumerState<FamilyMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(autoRefreshMonitoredUsersProvider);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text(
          'Mi Grafo Familiar',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _teal),
            onPressed: () => ref.invalidate(autoRefreshMonitoredUsersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _teal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar el mapa.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textPrimary),
            ),
          ),
        ),
        data: (users) => _buildMap(users),
      ),
    );
  }

  Widget _buildMap(List<MonitoredUser> users) {
    final withLocation = users.where((u) => u.hasLocation).toList();
    final initialCenter = withLocation.isNotEmpty
        ? LatLng(
            withLocation.first.ultimaLatitud!,
            withLocation.first.ultimaLongitud!,
          )
        : _fallbackCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            // Silver / light-grey tile that matches the neumorphic surface.
            TileLayer(
              urlTemplate:
                  'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.jepo.app',
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1,
            ),

            // Active alerts on top (so the pulse is never hidden).
            MarkerLayer(
              markers: _buildMarkers(withLocation, onlyAlerts: false),
            ),
            MarkerLayer(markers: _buildMarkers(withLocation, onlyAlerts: true)),
          ],
        ),

        // ─── Empty state overlay ────────────────────────────────────────
        if (withLocation.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.35),
                    offset: const Offset(5, 5),
                    blurRadius: 12,
                  ),
                  const BoxShadow(
                    color: _shadowLight,
                    offset: Offset(-5, -5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, color: _teal, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Sin ubicaciones aún',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Nadie te ha registrado como contacto de emergencia verificado, o tus contactos aún no han compartido su ubicación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ─── Legend ─────────────────────────────────────────────────────
        Positioned(bottom: 20, left: 20, child: _LegendChip()),
      ],
    );
  }

  List<Marker> _buildMarkers(
    List<MonitoredUser> users, {
    required bool onlyAlerts,
  }) {
    final filtered = users.where(
      (u) => onlyAlerts ? u.tieneAlertaActiva : !u.tieneAlertaActiva,
    );

    return filtered
        .map(
          (u) => Marker(
            point: LatLng(u.ultimaLatitud!, u.ultimaLongitud!),
            width: 80,
            height: 80,
            child: _UserPin(user: u, onTap: () => _showUserDetails(u)),
          ),
        )
        .toList(growable: false);
  }

  void _showUserDetails(MonitoredUser user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserDetailsSheet(user: user),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Pin Widget — teal for safe, red + pulse for active alert
// ═════════════════════════════════════════════════════════════════════════

class _UserPin extends StatelessWidget {
  final MonitoredUser user;
  final VoidCallback onTap;

  const _UserPin({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = user.tieneAlertaActiva ? _danger : _teal;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ─── Pulse ring (only for active alerts) ─────────────────
          if (user.tieneAlertaActiva)
            Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _danger.withValues(alpha: 0.35),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  duration: 1200.ms,
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.4, 1.4),
                )
                .fadeOut(duration: 1200.ms, begin: 0.8),

          // ─── Pin body ────────────────────────────────────────────
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials(user.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Details Bottom Sheet (Neumorphic)
// ═════════════════════════════════════════════════════════════════════════

class _UserDetailsSheet extends StatelessWidget {
  final MonitoredUser user;

  const _UserDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (user.tieneAlertaActiva ? _danger : _teal)
                        .withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.tieneAlertaActiva
                        ? Icons.warning_amber_rounded
                        : Icons.person_outline,
                    color: user.tieneAlertaActiva ? _danger : _teal,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (user.tieneAlertaActiva)
                        const Text(
                          '⚠ Alerta activa',
                          style: TextStyle(
                            color: _danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Text(
                          'Ubicación reciente',
                          style: TextStyle(
                            color: _teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.phone,
              label: 'Teléfono',
              value: user.telefono,
              onTap: () => launchUrl(Uri.parse('tel:${user.telefono}')),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.schedule,
              label: 'Última ubicación',
              value: _formatDate(user.fechaUltimaUbicacion),
            ),
            if (user.ultimaLatitud != null && user.ultimaLongitud != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.map,
                label: 'Abrir en Maps',
                value:
                    '${user.ultimaLatitud!.toStringAsFixed(5)}, ${user.ultimaLongitud!.toStringAsFixed(5)}',
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://maps.google.com/?q=${user.ultimaLatitud},${user.ultimaLongitud}',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Sin registro';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Hace unos segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    final d = local;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: _textPrimary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Legend chip
// ═════════════════════════════════════════════════════════════════════════

class _LegendChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: _teal),
          SizedBox(width: 4),
          Text(
            'Seguro',
            style: TextStyle(
              fontSize: 11,
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10),
          _LegendDot(color: _danger),
          SizedBox(width: 4),
          Text(
            'Alerta',
            style: TextStyle(
              fontSize: 11,
              color: _danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
