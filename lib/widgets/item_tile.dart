import 'package:flutter/material.dart';

import '../models/shopping_item.dart';

/// A list row with three gestures:
/// tap or swipe right — toggle bought; swipe left — delete; long press — edit.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = item.category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: ValueKey(item.id),
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.25,
            DismissDirection.endToStart: 0.4,
          },
          background: _SwipeBackground(
            color: const Color(0xFF2E7D4F),
            icon: item.isBought ? Icons.undo_rounded : Icons.check_rounded,
            label: item.isBought ? 'Вернуть' : 'Куплено',
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _SwipeBackground(
            color: scheme.error,
            icon: Icons.delete_outline_rounded,
            label: 'Удалить',
            alignment: Alignment.centerRight,
          ),
          // Swiping right only toggles: the row springs back instead of leaving.
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              onToggle();
              return false;
            }
            return true;
          },
          onDismissed: (_) => onDelete(),
          child: Material(
            color: scheme.surfaceContainerLowest,
            child: InkWell(
              onTap: onToggle,
              onLongPress: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    _CheckMark(checked: item.isBought, color: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: item.isBought
                              ? scheme.onSurface.withValues(alpha: 0.4)
                              : scheme.onSurface,
                          decoration: item.isBought
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: scheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 8),
                      _QuantityBadge(
                        quantity: item.quantity,
                        color: accent,
                        faded: item.isBought,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        scale: checked ? 1 : 0,
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({
    required this.quantity,
    required this.color,
    required this.faded,
  });

  final int quantity;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: faded ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '×$quantity',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(icon, color: Colors.white),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    final isLeft = alignment == Alignment.centerLeft;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: isLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: isLeft ? content : content.reversed.toList(),
        ),
      ),
    );
  }
}
