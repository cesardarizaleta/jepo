import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JepoPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<bool>? onValidityChanged;

  const JepoPhoneInput({
    super.key,
    required this.controller,
    this.label = 'Numero de telefono',
    this.enabled = true,
    this.onValidityChanged,
  });

  @override
  State<JepoPhoneInput> createState() => _JepoPhoneInputState();
}

class _JepoPhoneInputState extends State<JepoPhoneInput> {
  static const List<String> _prefixes = <String>[
    '0412',
    '0422',
    '0414',
    '0424',
    '0416',
    '0426',
  ];

  static const Color _surface = Color(0xFFEEEEEE);
  static const Color _text = Color(0xFF747877);
  static const Color _success = Color(0xFF7FCCC4);
  static const Color _danger = Color(0xFFFF5151);
  static const Color _shadowDark = Color(0xFFA3B1C6);

  final TextEditingController _localNumberController = TextEditingController();
  String _selectedPrefix = _prefixes.first;

  bool get _isValid => _localNumberController.text.length == 7;

  @override
  void initState() {
    super.initState();
    _hydrateFromFullPhone(widget.controller.text);
    _localNumberController.addListener(_syncFullController);
    widget.controller.addListener(_syncFromExternalController);
  }

  @override
  void didUpdateWidget(covariant JepoPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromExternalController);
      widget.controller.addListener(_syncFromExternalController);
      _hydrateFromFullPhone(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _localNumberController.removeListener(_syncFullController);
    widget.controller.removeListener(_syncFromExternalController);
    _localNumberController.dispose();
    super.dispose();
  }

  void _syncFromExternalController() {
    final current = _buildFullPhone(
      _selectedPrefix,
      _localNumberController.text,
    );
    if (_digitsOnly(widget.controller.text) != current) {
      _hydrateFromFullPhone(widget.controller.text);
    }
  }

  void _hydrateFromFullPhone(String raw) {
    final local = _toLocalPhone(raw);
    final resolvedPrefix = _resolvePrefix(local);
    final remainder = local.startsWith(resolvedPrefix)
        ? local.substring(resolvedPrefix.length)
        : '';

    _selectedPrefix = resolvedPrefix;
    _localNumberController.value = TextEditingValue(
      text: remainder.length > 7 ? remainder.substring(0, 7) : remainder,
      selection: TextSelection.collapsed(
        offset: remainder.length > 7 ? 7 : remainder.length,
      ),
    );
    widget.onValidityChanged?.call(_isValid);
    if (mounted) {
      setState(() {});
    }
  }

  void _syncFullController() {
    final full = _buildFullPhone(_selectedPrefix, _localNumberController.text);
    if (_digitsOnly(widget.controller.text) != full) {
      widget.controller.value = TextEditingValue(
        text: full,
        selection: TextSelection.collapsed(offset: full.length),
      );
    }
    widget.onValidityChanged?.call(_isValid);
    if (mounted) {
      setState(() {});
    }
  }

  static String _digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  static String _buildFullPhone(String prefix, String remainder) =>
      '$prefix$remainder';

  static String _toLocalPhone(String raw) {
    final d = _digitsOnly(raw);
    if (d.length == 11 && d.startsWith('0')) return d;
    if (d.length == 10 && !d.startsWith('0')) return '0$d';
    if (d.length == 12 && d.startsWith('58')) return '0${d.substring(2)}';
    return d;
  }

  String _resolvePrefix(String local) {
    for (final prefix in _prefixes) {
      if (local.startsWith(prefix)) return prefix;
    }
    return _prefixes.first;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isValid ? _success : _danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: activeColor.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _shadowDark.withValues(alpha: 0.24),
                offset: const Offset(4, 4),
                blurRadius: 9,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 9,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.phone,
                  color: widget.enabled ? _text : _text.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 10),
                _buildPrefixSelector(),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _localNumberController,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '0000000',
                      hintStyle: TextStyle(color: _text.withValues(alpha: 0.6)),
                    ),
                    maxLength: 7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrefixSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _shadowDark.withValues(alpha: 0.22),
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPrefix,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _text.withValues(alpha: 0.9),
          ),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: _surface,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          onChanged: widget.enabled
              ? (value) {
                  if (value == null) return;
                  _selectedPrefix = value;
                  _syncFullController();
                }
              : null,
          items: _prefixes
              .map(
                (prefix) => DropdownMenuItem<String>(
                  value: prefix,
                  child: Text(prefix),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
