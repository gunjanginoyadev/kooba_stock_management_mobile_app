import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';

class StockUsageScreen extends StatefulWidget {
  const StockUsageScreen({super.key});

  @override
  State<StockUsageScreen> createState() => _StockUsageScreenState();
}

class _StockUsageScreenState extends State<StockUsageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  int quantity = 5;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Use Stock',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Record where and how stock is used.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Item',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            _DropdownLikeField(
              hint: 'Search by name or SKU...',
            ),
            const SizedBox(height: 24),
            const Text(
              'QUANTITY USED',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        quantity = (quantity - 1).clamp(0, 999999);
                      });
                    },
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'UNITS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _QtyButton(
                    icon: Icons.add,
                    isPrimary: true,
                    onTap: () {
                      setState(() {
                        quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Usage Location / Notes',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Zone B – Line 1, Project reference…',
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter usage location or note';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Save Usage Entry',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DropdownLikeField extends StatelessWidget {
  final String hint;

  const _DropdownLikeField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.unfold_more_rounded,
              color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppTheme.primaryBlue : AppTheme.borderColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}


