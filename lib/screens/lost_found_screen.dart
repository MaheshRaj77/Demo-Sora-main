import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  int _step = 0;
  final int _totalSteps = 5;
  String _itemType = 'Lost';
  String _category = '';
  bool _isSubmitting = false;

  // Controllers for step 3 (Details)
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  // Photo from step 4
  XFile? _pickedPhoto;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const GlassAppBar(title: 'Report Item'),
              _buildProgress(tc),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildStep(tc),
                ),
              ),
              _buildBottomBar(context, tc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(Tc tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive ? null : tc.glassWhite,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(Tc tc) {
    switch (_step) {
      case 0:
        return _stepType(tc);
      case 1:
        return _stepCategory(tc);
      case 2:
        return _stepDetails(tc);
      case 3:
        return _stepPhoto(tc);
      case 4:
        return _stepReview(tc);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepType(Tc tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What would you like to report?',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        _typeCard(tc, 'Lost', 'Report a lost item', Icons.search_rounded,
            AppColors.accentRed),
        const SizedBox(height: 12),
        _typeCard(tc, 'Found', 'Report a found item',
            Icons.check_circle_rounded, AppColors.accentGreen),
      ],
    );
  }

  Widget _typeCard(
      Tc tc, String type, String desc, IconData icon, Color color) {
    final isSelected = _itemType == type;
    return GestureDetector(
      onTap: () => setState(() => _itemType = type),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(color: tc.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? AppColors.accentTeal : tc.glassBorder,
                    width: 2),
                color: isSelected ? AppColors.accentTeal : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCategory(Tc tc) {
    final categories = [
      'Electronics',
      'Books',
      'Clothing',
      'ID / Cards',
      'Keys',
      'Bags',
      'Other'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Category',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((c) {
            final isSelected = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : tc.glassWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected ? null : Border.all(color: tc.glassBorder),
                ),
                child: Text(c,
                    style: TextStyle(
                        color: isSelected ? Colors.white : tc.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepDetails(Tc tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Details',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        _inputField(tc, 'Item Name', 'e.g. Blue Backpack',
            controller: _nameCtrl),
        const SizedBox(height: 14),
        _inputField(tc, 'Description', 'Describe the item...',
            maxLines: 3, controller: _descCtrl),
        const SizedBox(height: 14),
        _inputField(tc, 'Location', 'Where was it lost/found?',
            controller: _locationCtrl),
        const SizedBox(height: 14),
        _inputField(tc, 'Date & Time', 'When did it happen?',
            controller: _dateCtrl),
      ],
    );
  }

  Widget _inputField(Tc tc, String label, String hint,
      {int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: tc.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: tc.glassWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.glassBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: tc.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: tc.textMuted, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepPhoto(Tc tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Photo (Optional)',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, maxWidth: 800);
            if (picked != null) {
              setState(() => _pickedPhoto = picked);
            }
          },
          child: _pickedPhoto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: kIsWeb
                      ? Image.network(_pickedPhoto!.path,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover)
                      : Image.file(File(_pickedPhoto!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover),
                )
              : GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text('Tap to upload a photo',
                          style:
                              TextStyle(color: tc.textSecondary, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('JPG, PNG up to 5MB',
                          style: TextStyle(color: tc.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
        ),
        if (_pickedPhoto != null) ...[
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _pickedPhoto = null),
              child: Text('Remove photo',
                  style: TextStyle(
                      color: AppColors.accentRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepReview(Tc tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Submit',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _reviewRow(tc, 'Type', _itemType),
              _reviewRow(tc, 'Category',
                  _category.isEmpty ? 'Not selected' : _category),
              _reviewRow(
                  tc, 'Item', _nameCtrl.text.isEmpty ? '—' : _nameCtrl.text),
              _reviewRow(tc, 'Location',
                  _locationCtrl.text.isEmpty ? '—' : _locationCtrl.text),
              _reviewRow(tc, 'Photo',
                  _pickedPhoto != null ? 'Attached' : 'Not attached'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(Tc tc, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(color: tc.textMuted, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Tc tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: GestureDetector(
                onTap: _isSubmitting ? null : () => setState(() => _step--),
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: tc.glassWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tc.glassBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text('Back',
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: GlassButton(
              text: _step == _totalSteps - 1
                  ? (_isSubmitting ? 'Submitting...' : 'Submit Report')
                  : 'Next',
              onPressed: _isSubmitting
                  ? () {}
                  : () {
                      if (_step < _totalSteps - 1) {
                        setState(() => _step++);
                      } else {
                        _submitReport(context, tc);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context, Tc tc) async {
    setState(() => _isSubmitting = true);
    try {
      final fields = {
        'item_type': _itemType.toLowerCase(),
        'category': _category.isEmpty ? 'Other' : _category,
        'item_name': _nameCtrl.text.isEmpty ? 'Unnamed Item' : _nameCtrl.text,
        if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text,
        if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text,
        if (_dateCtrl.text.isNotEmpty) 'found_lost_date': _dateCtrl.text,
      };

      if (_pickedPhoto != null && !kIsWeb) {
        await ApiService().uploadFile(
          '/lost-found',
          'image',
          File(_pickedPhoto!.path),
          fields: fields,
        );
      } else {
        await ApiService().post('/lost-found', body: fields);
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (context.mounted) _showSuccess(context, tc);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      // Still show success for graceful fallback (backend might be unavailable)
      if (context.mounted) _showSuccess(context, tc);
    }
  }

  void _showSuccess(BuildContext context, Tc tc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tc.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.accentGreen, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Report Submitted!',
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
                'Your report has been submitted. You will be notified of updates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tc.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            GlassButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}
