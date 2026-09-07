import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/item_image.dart';
import '../utils/constants.dart';

class ItemDetailScreen extends StatefulWidget {
  final WardrobeItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _editing = false;
  late TextEditingController _typeCtrl;
  late TextEditingController _colorCtrl;
  late String _category;
  late String _pattern;
  late String _style;
  late String _fit;
  late String _season;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController(text: widget.item.type);
    _colorCtrl = TextEditingController(text: widget.item.color);
    _category = widget.item.category;
    _pattern = widget.item.pattern;
    _style = widget.item.style;
    _fit = widget.item.fit;
    _season = widget.item.season;
  }

  Future<void> _save() async {
    final updated = widget.item.copyWith(
      category: _category,
      type: _typeCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
      pattern: _pattern,
      style: _style,
      fit: _fit,
      season: _season,
    );
    await context.read<WardrobeProvider>().updateItem(updated);
    if (!mounted) return;
    setState(() => _editing = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will remove the item from your wardrobe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<WardrobeProvider>().deleteItem(widget.item.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.item.type),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
            onPressed: () =>
                _editing ? _save() : setState(() => _editing = true),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ItemImage(
              item: widget.item,
              size: 220,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          if (!_editing) ...[
            _infoRow('Category', '${ItemCategory.emoji(_category)} $_category'),
            _infoRow('Type', widget.item.type),
            _infoRow('Color', widget.item.color),
            _infoRow('Pattern', widget.item.pattern),
            _infoRow('Style', widget.item.style),
            _infoRow('Fit', widget.item.fit),
            _infoRow('Season', widget.item.season),
            if (widget.item.brand.isNotEmpty)
              _infoRow('Brand', widget.item.brand),
            _infoRow('Worn', '${widget.item.timesWorn} times'),
          ] else ...[
            _dropdownField(
              'Category',
              _category,
              ItemCategory.all,
              (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _textField('Type', _typeCtrl),
            const SizedBox(height: 12),
            _textField('Color', _colorCtrl),
            const SizedBox(height: 12),
            _dropdownField(
              'Pattern',
              _pattern,
              AppConstants.patterns,
              (v) => setState(() => _pattern = v),
            ),
            const SizedBox(height: 12),
            _dropdownField(
              'Style',
              _style,
              AppConstants.styles,
              (v) => setState(() => _style = v),
            ),
            const SizedBox(height: 12),
            _dropdownField(
              'Fit',
              _fit,
              AppConstants.fits,
              (v) => setState(() => _fit = v),
            ),
            const SizedBox(height: 12),
            _dropdownField(
              'Season',
              _season,
              AppConstants.seasons,
              (v) => setState(() => _season = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('SAVE CHANGES'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextField(controller: ctrl),
      ],
    );
  }

  Widget _dropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final safeValue = options.contains(value) ? value : options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
