import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryNameController.dispose();
    _subcategoryController.dispose();
    super.dispose();
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // For now just pop back to previous screen.
                    context.pop();
                  }
                },
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


