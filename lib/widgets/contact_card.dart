import 'package:flutter/material.dart';

/// Verification status rendered by [ContactCard].
///
/// Mirrors the backend's `estado_verificacion` values so the UI can decide
/// whether to show the "Verificar" CTA and the PENDING badge.
enum ContactCardStatus { pending, verified, rejected }

/// A neumorphic contact card with inline edit/delete + verification flow.
class ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final int priority;
  final ContactCardStatus status;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  /// Invoked when the user taps the "Verificar" button on a PENDING card.
  /// Not called when [status] is not pending.
  final VoidCallback? onVerify;

  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.priority,
    required this.onEdit,
    required this.onDelete,
    this.status = ContactCardStatus.verified,
    this.isSelected = false,
    this.onTap,
    this.onVerify,
  });

  // ─── Palette ───────────────────────────────────────────────────────────
  static const Color _surface = Color(0xFFEEEEEE);
  static const Color _accent = Color(0xFF7FCCC4);
  static const Color _danger = Color(0xFFFF5151);
  static const Color _textPrimary = Color(0xFF747877);
  static const Color _shadowDark = Color(0xFFA3B1C6);
  static const Color _shadowLight = Colors.white;

  bool get _isPending => status == ContactCardStatus.pending;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: _shadowDark,
                offset: Offset(5, 5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: _shadowLight,
                offset: Offset(-5, -5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main row
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInfo()),
                  const SizedBox(width: 8),
                  _NeumorphicCircleButton(
                    icon: Icons.edit_outlined,
                    iconColor: _accent,
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 10),
                  _NeumorphicCircleButton(
                    icon: Icons.delete_outline,
                    iconColor: _danger,
                    onPressed: onDelete,
                  ),
                ],
              ),

              // PENDING: show verify CTA below
              if (_isPending) ...[
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x22A3B1C6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Aún no verificado. Pide el código al contacto.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _VerifyPillButton(onPressed: onVerify ?? () {}),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: _accent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_isPending) const _PendingBadge(),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Prioridad $priority',
          style: TextStyle(
            color: _textPrimary.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          phone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _textPrimary.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── PENDING badge ─────────────────────────────────────────────────────────

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_bottom, size: 11, color: Color(0xFFB97A10)),
          SizedBox(width: 4),
          Text(
            'Pendiente',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFB97A10),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Verify pill button ────────────────────────────────────────────────────

class _VerifyPillButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _VerifyPillButton({required this.onPressed});

  @override
  State<_VerifyPillButton> createState() => _VerifyPillButtonState();
}

class _VerifyPillButtonState extends State<_VerifyPillButton> {
  bool _pressed = false;

  static const Color _surface = Color(0xFFEEEEEE);
  static const Color _accent = Color(0xFF7FCCC4);
  static const Color _shadowDark = Color(0xFFA3B1C6);
  static const Color _shadowLight = Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: _shadowLight.withValues(alpha: 0.9),
                    offset: const Offset(-1, -1),
                    blurRadius: 3,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: _shadowDark,
                    offset: Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: _shadowLight,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: _accent),
            SizedBox(width: 6),
            Text(
              'Verificar',
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle action button ──────────────────────────────────────────────────

class _NeumorphicCircleButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _NeumorphicCircleButton({
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  State<_NeumorphicCircleButton> createState() =>
      _NeumorphicCircleButtonState();
}

class _NeumorphicCircleButtonState extends State<_NeumorphicCircleButton> {
  bool _pressed = false;

  static const Color _surface = Color(0xFFEEEEEE);
  static const Color _shadowDark = Color(0xFFA3B1C6);
  static const Color _shadowLight = Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.45),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: _shadowLight.withValues(alpha: 0.8),
                    offset: const Offset(-1, -1),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.35),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  const BoxShadow(
                    color: _shadowLight,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Icon(widget.icon, size: 18, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}
