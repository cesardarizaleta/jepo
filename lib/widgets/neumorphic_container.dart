import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isPressed;
  final Color? color;
  final bool useAnimation;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.isPressed = false,
    this.color,
    this.useAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? AppTheme.background;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: AppTheme.shadowLight.withValues(alpha: 0.5),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppTheme.shadowDark.withValues(alpha: 0.2),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.shadowDark.withValues(alpha: 0.35),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: Offset(-6, -6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );

    if (useAnimation) {
      return content
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
    }
    return content;
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 16.0,
    this.color,
    this.padding,
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
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: 100.ms,
        curve: Curves.easeInOut,
        child: NeumorphicContainer(
          padding: EdgeInsets.zero,
          borderRadius: widget.borderRadius,
          isPressed: _isPressed,
          color: widget.color,
          useAnimation: false,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class NeumorphicTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const NeumorphicTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.controller,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<NeumorphicTextField> createState() => _NeumorphicTextFieldState();
}

class _NeumorphicTextFieldState extends State<NeumorphicTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 0,
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
        controller: widget.controller,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        style: TextStyle(
          color: widget.enabled ? AppTheme.textDark : AppTheme.textLight,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          counterText: '',
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: AppTheme.textLight)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscured = !_obscured);
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintStyle: const TextStyle(color: AppTheme.textLight),
        ),
      ),
    );
  }
}
