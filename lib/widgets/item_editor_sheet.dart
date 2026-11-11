import 'package:flutter/material.dart';

import '../models/item_category.dart';
import '../models/shopping_item.dart';

/// What the editor returns; the caller decides whether it's an add or a save.
typedef ItemDraft = ({String name, int quantity, ItemCategory category});

/// Bottom sheet for adding a new item or editing [initial].
/// Resolves to `null` if the user dismissed it.
Future<ItemDraft?> showItemEditor(
  BuildContext context, {
  ShoppingItem? initial,
}) {
  return showModalBottomSheet<ItemDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _ItemEditor(initial: initial),
  );
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.initial});

  final ShoppingItem? initial;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late int _quantity = widget.initial?.quantity ?? 1;
  late ItemCategory _category = widget.initial?.category ?? ItemCategory.other;

  /// While true, the category follows what's typed. Picking a chip by hand
  /// (or editing an existing item) turns it off.
  late bool _autoCategory = widget.initial == null;
  bool _guessed = false;

  bool get _isEditing => widget.initial != null;
  bool get _canSubmit => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // Always rebuilds (the submit button depends on the text), and re-guesses
  // the category while it's still automatic.
  void _onNameChanged(String value) {
    setState(() {
      if (!_autoCategory) return;
      final guess = guessCategory(value);
      _guessed = guess != null;
      _category = guess ?? ItemCategory.other;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop<ItemDraft>((
      name: _name.text.trim(),
      quantity: _quantity,
      category: _category,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      // Keep the form above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? 'Изменить товар' : 'Новый товар',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('item-name'),
              controller: _name,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'Например, молоко',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: _onNameChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Количество', style: labelStyle),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Меньше',
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_quantity',
                    key: const Key('item-quantity'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Больше',
                  onPressed: _quantity < 99
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Категория', style: labelStyle),
                if (_autoCategory && _guessed) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'подобрана по названию',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ItemCategory.values)
                  ChoiceChip(
                    avatar: Icon(
                      category.icon,
                      size: 18,
                      color: category == _category
                          ? Colors.white
                          : category.color,
                    ),
                    label: Text(category.label),
                    selected: category == _category,
                    selectedColor: category.color,
                    labelStyle: TextStyle(
                      color: category == _category ? Colors.white : null,
                    ),
                    onSelected: (_) => setState(() {
                      _category = category;
                      _autoCategory = false;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
