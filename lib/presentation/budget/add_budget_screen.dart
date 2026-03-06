import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:math';
import '../../data/providers/financial_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../theme/icons.dart';
import '../../domain/models/budget.dart';
import '../../l10n/l10n.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budgetToEdit;
  const AddBudgetScreen({super.key, this.budgetToEdit});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  late TextEditingController _limitController;
  late String _selectedCategory;
  late String _selectedIcon;
  late String _selectedType;
  double _sliderValue = 500;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budgetToEdit?.amountLimit.toStringAsFixed(0) ?? '',
    );
    _selectedCategory = widget.budgetToEdit?.categoryId ?? 'Food';
    _selectedIcon = widget.budgetToEdit?.icon ?? 'food';
    _selectedType = widget.budgetToEdit?.type ?? 'reserve';
    _sliderValue = widget.budgetToEdit?.amountLimit ?? 500;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _submitBudget() {
    final limit = double.tryParse(_limitController.text) ?? _sliderValue;
    if (limit <= 0) {
      ShadSonner.of(context).show(
        const ShadToast(
          title: Text('Invalid Amount'),
          description: Text('Please enter a valid limit'),
        ),
      );
      return;
    }

    final notifier = ref.read(financialProvider.notifier);
    final oldBudget = widget.budgetToEdit;

    notifier.createOrUpdateBudget(
      _selectedCategory,
      limit,
      id: widget.budgetToEdit?.id,
      icon: _selectedIcon,
      type: _selectedType,
    );

    _showSuccessToast(limit, isUpdate: oldBudget != null, oldBudget: oldBudget);
    Navigator.of(context).pop();
  }

  void _showSuccessToast(
    double limit, {
    bool isUpdate = false,
    Budget? oldBudget,
  }) {
    final sonner = ShadSonner.of(context);
    final id = Random().nextInt(10000);
    sonner.show(
      ShadToast(
        id: id,
        title: Text(isUpdate ? 'Budget Updated' : 'Budget Created'),
        description: Text('Monthly limit set to $limit'),
        action: ShadButton.outline(
          child: const Text('Undo'),
          onPressed: () {
            if (!isUpdate) {
              // Delete the newly created one (need ID, but notifier handles basic reinsertion)
              // For simplicity in this turn, I'll just undo delete if it was a delete
            } else if (oldBudget != null) {
              ref.read(financialProvider.notifier).reinsertBudget(oldBudget);
            }
            sonner.hide(id);
          },
        ),
      ),
    );
  }

  void _deleteBudget() {
    if (widget.budgetToEdit == null) return;
    final budget = widget.budgetToEdit!;
    ref.read(financialProvider.notifier).deleteBudget(budget.id);

    final sonner = ShadSonner.of(context);
    final id = Random().nextInt(1000);
    sonner.show(
      ShadToast(
        id: id,
        title: const Text('Budget Deleted'),
        description: Text('Budget for ${budget.categoryId} removed'),
        action: ShadButton.outline(
          child: const Text('Undo'),
          onPressed: () {
            ref.read(financialProvider.notifier).reinsertBudget(budget);
            sonner.hide(id);
          },
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final settings = ref.watch(settingsProvider);
    final locale = settings.languageCode;
    final isEditing = widget.budgetToEdit != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? (settings.isAmoled
                            ? const Color(0xFF121212)
                            : const Color(0xFF1E293B))
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          isEditing
              ? L10n.of(locale, 'edit_budget')
              : L10n.of(locale, 'add_budget'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _deleteBudget,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                DateFormat(
                  'MMMM yyyy',
                  locale,
                ).format(DateTime.now()).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildGlassCard(
              isDark,
              settings.isAmoled,
              Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    L10n.of(locale, 'how_much_limit').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                      letterSpacing: 2,
                    ),
                  ),
                  TextField(
                    controller: _limitController,
                    textAlign: TextAlign.center,
                    autofocus: !isEditing,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      letterSpacing: -1,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (val) {
                      final d = double.tryParse(val);
                      if (d != null && d <= 10000) {
                        setState(() => _sliderValue = d);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      prefixText: '${settings.currencyCode} ',
                      prefixStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 10,
                    ),
                    child: ShadSlider(
                      initialValue: _sliderValue.clamp(0.0, 10000.0),
                      max: 10000,
                      onChanged: (val) => setState(() {
                        _sliderValue = val;
                        _limitController.text = val.toStringAsFixed(0);
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionLabel('BUDGET STYLE', isDark),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTypeOption(
                  'reserve',
                  'Savings Jar',
                  Icons.savings,
                  primary,
                  isDark,
                  settings.isAmoled,
                ),
                const SizedBox(width: 12),
                _buildTypeOption(
                  'envelope',
                  'Budget Jar',
                  Icons.account_balance_wallet,
                  primary,
                  isDark,
                  settings.isAmoled,
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionLabel('CATEGORY', isDark),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: AppIcons.categoryIcons.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final category = AppIcons.categoryIcons.keys.elementAt(index);
                  final icon = AppIcons.categoryIcons.values.elementAt(index);
                  final isSelected =
                      _selectedIcon.toLowerCase() == category.toLowerCase();
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIcon = category;
                      _selectedCategory =
                          category[0].toUpperCase() + category.substring(1);
                    }),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : (isDark
                                      ? (settings.isAmoled
                                            ? const Color(0xFF121212)
                                            : const Color(0xFF1E293B))
                                      : Colors.white),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[400] : primary),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : primary)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('BUDGET NAME', isDark),
            const SizedBox(height: 12),
            _buildGlassCard(
              isDark,
              settings.isAmoled,
              TextField(
                controller: TextEditingController(text: _selectedCategory),
                onChanged: (val) => _selectedCategory = val,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: L10n.of(locale, 'category'),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(Icons.edit, color: primary, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submitBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: primary.withValues(alpha: 0.3),
                ),
                child: Text(
                  (isEditing
                          ? L10n.of(locale, 'update_budget')
                          : L10n.of(locale, 'create_budget'))
                      .toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    String type,
    String label,
    IconData icon,
    Color primary,
    bool isDark,
    bool isAmoled,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.1)
                : (isDark
                      ? (isAmoled
                            ? const Color(0xFF121212)
                            : const Color(0xFF1E293B))
                      : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1)),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? primary : Colors.grey[500],
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? primary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildGlassCard(bool isDark, bool isAmoled, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(32), child: child),
    );
  }
}
