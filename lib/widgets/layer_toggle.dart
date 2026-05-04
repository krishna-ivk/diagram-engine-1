import 'package:flutter/material.dart';

class LayerToggleBar extends StatelessWidget {
  final bool showValues;
  final bool showHints;
  final bool showLabels;
  final ValueChanged<bool> onValuesChanged;
  final ValueChanged<bool> onHintsChanged;
  final ValueChanged<bool> onLabelsChanged;

  const LayerToggleBar({
    super.key,
    required this.showValues,
    required this.showHints,
    required this.showLabels,
    required this.onValuesChanged,
    required this.onHintsChanged,
    required this.onLabelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            icon: Icons.numbers,
            label: 'Values',
            active: showValues,
            onTap: () => onValuesChanged(!showValues),
          ),
          const SizedBox(width: 4),
          _ToggleChip(
            icon: Icons.tips_and_updates_outlined,
            label: 'Hints',
            active: showHints,
            onTap: () => onHintsChanged(!showHints),
          ),
          const SizedBox(width: 4),
          _ToggleChip(
            icon: Icons.label_outline,
            label: 'Labels',
            active: showLabels,
            onTap: () => onLabelsChanged(!showLabels),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.blue.shade100 : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
