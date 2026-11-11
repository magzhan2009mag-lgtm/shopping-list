import 'package:flutter/material.dart';

import '../data/shopping_repository.dart';
import '../models/shopping_item.dart';
import '../utils/ru_plural.dart';
import '../widgets/category_header.dart';
import '../widgets/item_editor_sheet.dart';
import '../widgets/item_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final ShoppingRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ShoppingRepository get _repo => widget.repository;

  /// Rows swiped away whose delete hasn't reached the box yet. A dismissed
  /// [Dismissible] must leave the tree right away, so hide it until then.
  final _pendingDelete = <String>{};

  // ---- actions ---------------------------------------------------------------

  Future<void> _add() async {
    final draft = await showItemEditor(context);
    if (draft == null) return;
    await _repo.add(
      name: draft.name,
      quantity: draft.quantity,
      category: draft.category,
    );
  }

  Future<void> _edit(ShoppingItem item) async {
    final draft = await showItemEditor(context, initial: item);
    if (draft == null) return;
    await _repo.save(
      item.copyWith(
        name: draft.name,
        quantity: draft.quantity,
        category: draft.category,
      ),
    );
  }

  Future<void> _delete(ShoppingItem item) async {
    setState(() => _pendingDelete.add(item.id));
    await _repo.delete(item);
    _pendingDelete.remove(item.id);
    _showUndo('«${item.name}» удалён', () => _repo.save(item));
  }

  Future<void> _clearBought(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить купленные?'),
        content: Text(
          'Из списка уйдут $count '
          '${ruPlural(count, 'товар', 'товара', 'товаров')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await _repo.clearBought();
    _showUndo('Удалено: ${removed.length}', () => _repo.restoreAll(removed));
  }

  void _showUndo(String message, VoidCallback undo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: 'Отменить', onPressed: undo),
          // With an action, SnackBar stays until dismissed by default;
          // an undo offer should go away on its own.
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ---- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repo.changes,
      builder: (context, _) {
        final all = _repo.items
            .where((i) => !_pendingDelete.contains(i.id))
            .toList();
        final hideBought = _repo.hideBought;
        final groups = groupByCategory(all, hideBought: hideBought);
        final bought = all.where((i) => i.isBought).length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.medium(
                pinned: true,
                title: const Text('Список покупок'),
                actions: [
                  IconButton(
                    tooltip: hideBought
                        ? 'Показать купленные'
                        : 'Скрыть купленные',
                    onPressed: () => _repo.setHideBought(!hideBought),
                    isSelected: hideBought,
                    icon: const Icon(Icons.visibility_outlined),
                    selectedIcon: const Icon(Icons.visibility_off_outlined),
                  ),
                  IconButton(
                    tooltip: 'Удалить купленные',
                    onPressed: bought > 0 ? () => _clearBought(bought) : null,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              if (all.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ProgressCard(bought: bought, total: all.length),
                ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: all.isEmpty
                      ? const _EmptyState(
                          icon: Icons.shopping_basket_outlined,
                          title: 'Список пуст',
                          subtitle:
                              'Нажмите «Добавить», чтобы внести первый '
                              'товар',
                        )
                      : _EmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'Всё куплено',
                          subtitle: 'Купленные товары скрыты',
                          action: TextButton(
                            onPressed: () => _repo.setHideBought(false),
                            child: const Text('Показать'),
                          ),
                        ),
                ),
              for (final group in groups)
                SliverMainAxisGroup(
                  slivers: [
                    PinnedHeaderSliver(child: CategoryHeader(group: group)),
                    SliverList.list(
                      children: [
                        for (final item in group.visible)
                          ItemTile(
                            key: ValueKey(item.id),
                            item: item,
                            onToggle: () => _repo.toggleBought(item),
                            onDelete: () => _delete(item),
                            onEdit: () => _edit(item),
                          ),
                      ],
                    ),
                  ],
                ),
              if (groups.isNotEmpty)
                const SliverToBoxAdapter(child: _GestureHint()),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить'),
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.bought, required this.total});

  final int bought;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final left = total - bought;
    final done = left == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  done ? 'Готово!' : '$left',
                  style: theme.textTheme.headlineMedium!.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    done
                        ? 'всё из списка куплено'
                        : '${ruPlural(left, 'товар', 'товара', 'товаров')} '
                              'осталось купить',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  '$bought / $total',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : bought / total),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: scheme.primary,
                backgroundColor: scheme.onPrimaryContainer.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: muted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(color: muted),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _GestureHint extends StatelessWidget {
  const _GestureHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final style = theme.textTheme.bodySmall!.copyWith(color: color);

    Widget hint(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          hint(Icons.east_rounded, 'свайп — куплено'),
          hint(Icons.west_rounded, 'свайп — удалить'),
          hint(Icons.touch_app_outlined, 'удержание — изменить'),
        ],
      ),
    );
  }
}
