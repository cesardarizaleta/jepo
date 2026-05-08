import 'package:flutter/material.dart';

class ContactPrioritySelector extends StatelessWidget {
  final int selectedPriority;
  final ValueChanged<int> onChanged;

  const ContactPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
  });

  static const Color _primaryColor = Color(0xFF7FCCC4);
  static const Color _dangerColor = Color(0xFFFF5151);
  static const Color _neutralTextColor = Color(0xFF747877);

  static const List<_PriorityOptionData> _options = <_PriorityOptionData>[
    _PriorityOptionData(
      priority: 1,
      title: 'Alta',
      subtitle: 'Se llama primero',
      icon: Icons.notifications_active_rounded,
      accentColor: _dangerColor,
    ),
    _PriorityOptionData(
      priority: 2,
      title: 'Media',
      subtitle: 'Segundo contacto',
      icon: Icons.shield_outlined,
      accentColor: _primaryColor,
    ),
    _PriorityOptionData(
      priority: 3,
      title: 'Baja',
      subtitle: 'Ultimo recurso',
      icon: Icons.schedule_rounded,
      accentColor: _neutralTextColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Parent owns selection state; this widget renders and emits state changes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 360;

        final tiles = _options
            .map(
              (option) => _PriorityOptionTile(
                data: option,
                selected: selectedPriority == option.priority,
                onTap: () => onChanged(option.priority),
              ),
            )
            .toList(growable: false);

        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                tiles[i],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _PriorityOptionData {
  final int priority;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _PriorityOptionData({
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

class _PriorityOptionTile extends StatelessWidget {
  final _PriorityOptionData data;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityOptionTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  static const Color _backgroundColor = Color(0xFFEEEEEE);
  static const Color _neutralTextColor = Color(0xFF747877);
  static const Color _shadowDark = Color(0xFFA3B1C6);

  @override
  Widget build(BuildContext context) {
    // Selected state uses a pressed (inset-like) style with semantic accent color.
    final Color foreground = selected ? data.accentColor : _neutralTextColor;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Prioridad ${data.priority} ${data.title}',
      hint: selected ? 'Seleccionada' : 'Toca para seleccionar esta prioridad',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? <Color>[
                        Colors.white.withValues(alpha: 0.20),
                        _backgroundColor,
                        _backgroundColor,
                      ]
                    : <Color>[
                        Colors.white.withValues(alpha: 0.65),
                        _backgroundColor,
                      ],
              ),
              border: Border.all(
                color: selected
                    ? data.accentColor.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.80),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: _shadowDark.withValues(alpha: 0.24),
                        offset: const Offset(2, 2),
                        blurRadius: 5,
                      ),
                    ]
                  : <BoxShadow>[
                      BoxShadow(
                        color: _shadowDark.withValues(alpha: 0.35),
                        offset: const Offset(7, 7),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-7, -7),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected
                              ? data.accentColor.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${data.priority}',
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(data.icon, size: 18, color: foreground),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    data.title,
                                    style: TextStyle(
                                      color: foreground,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.subtitle,
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selected ? 'Seleccionada' : 'Toca para elegir',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
