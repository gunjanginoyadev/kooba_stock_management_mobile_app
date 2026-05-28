import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
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
  bool _isSaving = false;
  final _repository = ItemsRepository();

  /// Turns a caught exception into a short, clear message for the user.
  static String _userFriendlySaveError(Object e) {
    final str = e.toString();
    if (str.contains('already exists')) {
      return 'An item with this name already exists. Use a different name.';
    }
    final withoutPrefix = str.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (withoutPrefix.length > 80) {
      return 'Failed to save. Please try again.';
    }
    return withoutPrefix.isEmpty ? 'Failed to save.' : withoutPrefix;
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
    if (!SupabaseConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend not configured. Add Supabase credentials.'),
            backgroundColor: Color(0xFFE65100),
          ),
        );
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final qty10 = int.tryParse(_qty10ftController.text.trim()) ?? 0;
      final qty12 = int.tryParse(_qty12ftController.text.trim()) ?? 0;

      await _repository.addStockSheetItem(
        typeName: _typeController.text.trim(),
        typeImageUrl: _typeImageUrlController.text.trim(),
        code: _codeController.text.trim(),
        finish: _finishController.text.trim(),
        qty10ft: qty10,
        qty12ft: qty12,
        remark: _remarkController.text.trim(),
      );
      if (mounted) {
        ToastHelper.success(context, 'Item added');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final message = _userFriendlySaveError(e);
        ToastHelper.error(context, message);
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Add item',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
                label: 'Type Image URL (optional)',
                hintText: 'https://…',
                keyboardType: TextInputType.url,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  if (!_isProbablyHttpUrl(v)) return 'Please enter a valid URL';
                  return null;
                },
              ),
              if (previewUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppTheme.cardBackground,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.cardBackground,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Image failed to load',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
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
              ],
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

