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
  final _nameController = TextEditingController();
  final _categoryNameController = TextEditingController();
  final _subcategoryController = TextEditingController();
  bool _isCategoryBased = false;
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
  void dispose() {
    _nameController.dispose();
    _categoryNameController.dispose();
    _subcategoryController.dispose();
    super.dispose();
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
      if (_isCategoryBased) {
        await _repository.addSpecialItem(
          categoryName: _categoryNameController.text.trim(),
          itemName: _subcategoryController.text.trim(),
        );
        if (mounted) {
          ToastHelper.success(context, 'Item added under category');
          context.pop();
        }
      } else {
        await _repository.addNormalItem(
          name: _nameController.text.trim(),
        );
        if (mounted) {
          ToastHelper.success(context, 'Normal item added');
          context.pop();
        }
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
              Text(
                'ITEM TYPE',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeChip(
                    label: 'Normal Item',
                    isSelected: !_isCategoryBased,
                    onTap: () {
                      setState(() => _isCategoryBased = false);
                    },
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Category-Based',
                    isSelected: _isCategoryBased,
                    onTap: () {
                      setState(() => _isCategoryBased = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_isCategoryBased) ...[
                AppTextField(
                  controller: _nameController,
                  label: 'Item Name',
                  hintText: 'e.g. Buff Board',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
              ] else ...[
                AppTextField(
                  controller: _categoryNameController,
                  label: 'Category Name',
                  hintText: 'e.g. Ply',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _subcategoryController,
                  label: 'Sub-Category',
                  hintText: 'e.g. Ply – 4x8',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one sub-category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sub-categories are added as free text. Duplicate names under the same category are not allowed.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


