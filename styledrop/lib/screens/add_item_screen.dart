import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';
import '../providers/profile_provider.dart';
import '../services/clothing_detection_service.dart';
import '../services/usage_limit_service.dart';
import '../utils/constants.dart';
import '../widgets/paywall.dart';

class AddItemScreen extends StatefulWidget {
  final String initialCategory;
  const AddItemScreen({super.key, required this.initialCategory});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

enum _Stage { pickPhoto, analyzing, review }

class _AddItemScreenState extends State<AddItemScreen> {
  _Stage _stage = _Stage.pickPhoto;
  String? _imagePath;
  Uint8List? _imageBytes;
  DetectionResult? _detection;
  String? _detectionError;

  late String _category;
  final _typeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  String _pattern = 'Plain';
  String _style = 'Streetwear';
  String _fit = 'Regular';
  String _season = 'All Season';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  Future<void> _pickImage(ImageSource source) async {
    final tier = context.read<ProfileProvider>().profile.subscriptionTier;
    final currentCount = context.read<WardrobeProvider>().totalItems;
    if (!UsageLimitService.canAddWardrobeItem(tier, currentCount)) {
      await showPaywall(
        context,
        reason:
            'Your wardrobe is at the Free plan limit of '
            '${UsageLimitService.freeWardrobeItemLimit} items. Upgrade for '
            'unlimited wardrobe storage.',
      );
      if (!mounted) return;
      return;
    }

    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imagePath = kIsWeb ? null : file.path;
        _imageBytes = bytes;
        _detectionError = null;
        _stage = _Stage.analyzing;
      });
      final result = await ClothingDetectionService.analyzeImage(
        imageBytes: bytes,
        suggestedCategory: _category,
      );
      if (!mounted) return;
      setState(() {
        _detection = result;
        _detectionError = result.isAiGenerated
            ? null
            : 'AI detection unavailable — using placeholder values. Please '
                  'review and correct the fields below.';
        _category = result.category;
        _typeCtrl.text = result.type;
        _colorCtrl.text = result.color;
        _pattern = result.pattern;
        _style = result.style;
        _fit = result.fit;
        _season = result.season;
        _stage = _Stage.review;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not access camera/gallery in this environment: $e',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final item = WardrobeItem(
      id: const Uuid().v4(),
      category: _category,
      type: _typeCtrl.text.trim().isEmpty ? 'Item' : _typeCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? 'Black' : _colorCtrl.text.trim(),
      pattern: _pattern,
      style: _style,
      fit: _fit,
      season: _season,
      brand: _brandCtrl.text.trim(),
      imagePath: _imagePath,
      imageBytes: kIsWeb ? _imageBytes : null,
    );
    await context.read<WardrobeProvider>().addItem(item);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to your wardrobe ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_stage) {
            _Stage.pickPhoto => _buildPickPhoto(context),
            _Stage.analyzing => _buildAnalyzing(context),
            _Stage.review => _buildReview(context),
          },
        ),
      ),
    );
  }

  Widget _buildPickPhoto(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('📸', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          'Add a $_category item',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI will automatically detect the category, color, style, and fit.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: const Text('TAKE PHOTO'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined, size: 20),
            label: const Text('UPLOAD PHOTO'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_imageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(_imageBytes!, height: 220, fit: BoxFit.cover),
          ),
        const SizedBox(height: 28),
        const CircularProgressIndicator(color: AppColors.ink),
        const SizedBox(height: 16),
        Text(
          'AI analyzing item...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Sending photo to the vision model for real-time analysis',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    return ListView(
      children: [
        if (_imageBytes != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _detection?.isAiGenerated == false
                ? AppColors.warning.withValues(alpha: 0.12)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                _detection?.isAiGenerated == false
                    ? Icons.warning_amber_rounded
                    : Icons.auto_awesome,
                size: 18,
                color: AppColors.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _detection != null
                      ? (_detection!.isAiGenerated
                            ? 'AI DETECTED (${(_detection!.confidence * 100).round()}% confidence)'
                            : 'AI DETECTION UNAVAILABLE — please review below')
                      : 'AI DETECTED',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
        if (_detectionError != null) ...[
          const SizedBox(height: 8),
          Text(
            _detectionError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: 16),
        _dropdownField(
          'Category',
          _category,
          ItemCategory.all,
          (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 12),
        _textField('Type', _typeCtrl, hint: 'e.g. Oversized T-Shirt'),
        const SizedBox(height: 12),
        _textField('Color', _colorCtrl, hint: 'e.g. Black'),
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
        const SizedBox(height: 12),
        _textField('Brand (optional)', _brandCtrl, hint: 'e.g. Nike'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('SAVE ITEM'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
        ),
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
          decoration: const InputDecoration(),
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
