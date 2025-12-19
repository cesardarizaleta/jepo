import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isPressed;
  final Color? color;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.isPressed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? AppTheme.background;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                // Inner shadow simulation (not natively supported easily without custom painter or plugins,
                // so we simulate "pressed" by inverting or flattening)
                // For simplicity in standard Flutter without plugins:
                // We'll just reduce elevation or make it flat.
                // A true inner shadow requires a custom painter or a package.
                // Let's stick to a "flat" look when pressed for now, or very subtle.
              ]
            : [
                BoxShadow(
                  color: AppTheme.shadowDark.withOpacity(0.3),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 12.0,
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color ?? AppTheme.background,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? [
                  // "Pressed" state - no shadow or inset simulation
                  // Simulating inset with a different color or gradient is complex without packages.
                  // We will just remove the shadow to make it look "pressed into" the surface.
                ]
              : [
                  BoxShadow(
                    color: AppTheme.shadowDark.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: AppTheme.shadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class NeumorphicTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final IconData? icon;
  final TextEditingController? controller;

  const NeumorphicTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        // Inset shadow simulation for input fields
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 0,
            // inset: true // Flutter BoxShadow doesn't support inset.
            // We usually simulate this by nesting containers or using a package.
            // For now, we'll use a "pressed" look (no shadow) or a subtle border.
          ),
          const BoxShadow(
            color: AppTheme.shadowLight,
            offset: Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.textLight)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintStyle: const TextStyle(color: AppTheme.textLight),
        ),
      ),
    );
  }
}
