import 'package:flutter/material.dart';

/// A neumorphic contact card with inline edit/delete action buttons.
///
/// Designed to be used inside a [ListView.builder]. Accepts [onEdit] and
/// [onDelete] callbacks so the parent can wire up backend logic.
class ContactCard extends StatelessWidget {
  /// Contact display name.
  final String name;

  /// Contact phone number (formatted for display).
  final String phone;

  /// Priority level (1 = highest, 3 = lowest).
  final int priority;

  /// Whether this card is visually selected.
  final bool isSelected;

  /// Called when the user taps the edit action button.
  final VoidCallback onEdit;

  /// Called when the user taps the delete action button.
  final VoidCallback onDelete;

  /// Called when the user taps the card body (e.g. to select it).
  final VoidCallback? onTap;

  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.priority,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
    this.onTap,
  });

  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color _surface = Color(0xFFEEEEEE);
  static const Color _accent = Color(0xFF7FCCC4);
  static const Color _danger = Color(0xFFFF5151);
  static const Color _textPrimary = Color(0xFF747877);

  // Neumorphic shadow colors
  static const Color _shadowDark = Color(0xFFA3B1C6);
  static const Color _shadowLight = Colors.white;

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
          child: Row(
            children: [
              // ─── Avatar ──────────────────────────────────────────────
              Container(
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
              ),
              const SizedBox(width: 14),

              // ─── Info (Expanded to prevent overflow) ─────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
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
                ),
              ),
              const SizedBox(width: 8),

              // ─── Action Buttons ──────────────────────────────────────
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
        ),
      ),
    );
  }

  /// Extracts up to 2 initials from the contact name.
  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small circular neumorphic button with press (inset) effect.
// ─────────────────────────────────────────────────────────────────────────────

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
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? [
                  // Inset-like effect: reduced, inverted shadows
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
                  // Elevated state
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
