import 'package:flutter/material.dart';

import '../data/shopping_repository.dart';

/// Section title that sticks to the top while its category is on screen.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.group});

  final CategoryGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = group.category;
    final done = group.remaining == 0;

    return ColoredBox(
      // Opaque, so rows scroll underneath without showing through.
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 20, 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, size: 18, color: category.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (done)
              Icon(Icons.check_circle_rounded, size: 18, color: category.color)
            else
              Text(
                '${group.boughtCount}/${group.items.length}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
