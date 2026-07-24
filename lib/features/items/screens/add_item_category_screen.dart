import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/stock/stock_refresh_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/toast_helper.dart';
import '../repository/items_repository.dart';

class AddItemCategoryScreen extends StatefulWidget {
  const AddItemCategoryScreen({super.key});

  @override
  State<AddItemCategoryScreen> createState() => _AddItemCategoryScreenState();
}

class _AddItemCategoryScreenState extends State<AddItemCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _typeImageUrlController = TextEditingController();
  final _codeController = TextEditingController();
  final _finishController = TextEditingController();
  final _qty10ftController = TextEditingController(text: '0');
  final _qty12ftController = TextEditingController(text: '0');
  final _remarkController = TextEditingController();
  final _repository = ItemsRepository();
  bool _isSaving = false;

  static String _userFriendlySaveError(Object e) {
    final str = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (str.contains('already exists')) {
      return 'An item with this name already exists. Use a different name.';
    }
    if (str.contains('Permission denied') ||
        str.contains('timed out') ||
        str.contains('not found') ||
        str.contains('unavailable')) {
      return str.length > 160 ? '${str.substring(0, 157)}…' : str;
    }
    if (str.length > 120) {
      return 'Failed to save. Please try again.';
    }
    return str.isEmpty ? 'Failed to save.' : str;
  }

  @override
  void initState() {
    super.initState();
    _typeImageUrlController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _typeController.dispose();
    _typeImageUrlController.dispose();
    _codeController.dispose();
    _finishController.dispose();
    _qty10ftController.dispose();
    _qty12ftController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  static bool _isProbablyHttpUrl(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!FirebaseConfig.isConfigured) {
      if (mounted) {
        ToastHelper.error(
          context,
          'Backend not configured. Check Firebase setup.',
        );
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final qty10 = int.tryParse(_qty10ftController.text.trim()) ?? 0;
      final qty12 = int.tryParse(_qty12ftController.text.trim()) ?? 0;
      final imageUrl = _typeImageUrlController.text.trim();

      await _repository.addStockSheetItem(
        typeName: _typeController.text.trim(),
        typeImageUrl: imageUrl.isEmpty ? null : imageUrl,
        code: _codeController.text.trim(),
        finish: _finishController.text.trim(),
        qty10ft: qty10,
        qty12ft: qty12,
        remark: _remarkController.text.trim(),
      );
      if (mounted) {
        StockRefreshNotifier.instance.notifyStockChanged();
        ToastHelper.success(context, 'Item added');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, _userFriendlySaveError(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _typeImageUrlController.text.trim();

    return AppScaffold(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Add item',
                    style: GoogleFonts.sora(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 64),
                ],
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _typeController,
                label: 'Type (Die/Profile)',
                hintText: 'e.g. HETVA DIE 2001',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _typeImageUrlController,
                label: 'Image URL (optional)',
                hintText: 'https://…',
                keyboardType: TextInputType.url,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  if (!_isProbablyHttpUrl(v)) return 'Please enter a valid URL';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: previewUrl.isEmpty
                      ? Center(
                          child: Text(
                            'Image preview appears here',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              url: previewUrl,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.zero,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _typeImageUrlController.clear(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _codeController,
                label: 'Code',
                hintText: 'e.g. KLF-07',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _finishController,
                label: 'Finish',
                hintText: 'e.g. BRUSH GOLD',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter finish';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _qty10ftController,
                      label: 'Qty (10 ft)',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Enter qty';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Invalid qty';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _qty12ftController,
                      label: 'Qty (12 ft)',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Enter qty';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Invalid qty';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _remarkController,
                label: 'Remark (optional)',
                hintText: 'e.g. Old / New / Notes',
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: 'Save Item',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
