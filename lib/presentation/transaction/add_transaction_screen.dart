import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:math';
import '../../data/providers/financial_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/icons.dart';
import '../../domain/models/transaction.dart' as t;
import '../../l10n/l10n.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final t.Transaction? transactionToEdit;
  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _transactionType = 'expense';
  String _entryType = 'default';
  int _recurrenceInterval = 1;
  String _recurrenceUnit = 'month';
  String _selectedCategory = 'Food';
  String _selectedIcon = 'food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _amountController.text = tx.amount.toString();
      _descriptionController.text = tx.description ?? '';
      _transactionType = tx.type;
      _entryType = tx.entryType;
      _recurrenceInterval = tx.recurrenceInterval ?? 1;
      _recurrenceUnit = tx.recurrenceUnit ?? 'month';
      _selectedCategory = tx.categoryId;
      _selectedIcon = tx.icon ?? 'food';
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) return;

      final notifier = ref.read(financialProvider.notifier);
      final isEditing = widget.transactionToEdit != null;

      if (isEditing) {
        notifier.updateTransaction(
          widget.transactionToEdit!.id,
          amount: amount,
          type: _transactionType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _selectedCategory,
          entryType: _entryType,
          recurrenceInterval: _entryType == 'recurring'
              ? _recurrenceInterval
              : null,
          recurrenceUnit: _entryType == 'recurring' ? _recurrenceUnit : null,
          date: _selectedDate,
          icon: _selectedIcon,
        );
      } else {
        notifier.addTransaction(
          amount: amount,
          type: _transactionType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _selectedCategory,
          entryType: _entryType,
          recurrenceInterval: _entryType == 'recurring'
              ? _recurrenceInterval
              : null,
          recurrenceUnit: _entryType == 'recurring' ? _recurrenceUnit : null,
          date: _selectedDate,
          icon: _selectedIcon,
        );
      }

      _showSuccessToast(amount, isEditing);
      Navigator.of(context).pop();
    }
  }

  void _showSuccessToast(double amount, bool isEditing) {
    final sonner = ShadSonner.of(context);
    final id = Random().nextInt(10000);
    sonner.show(
      ShadToast(
        id: id,
        title: Text(isEditing ? 'Transaction Updated' : 'Transaction Created'),
        description: Text('Amount: $amount set for $_selectedCategory'),
        action: ShadButton.outline(
          child: const Text('Undo'),
          onPressed: () {
            // Reinsert logic would go here if we tracked the creation.
            // For now, it's a confirmation toast.
            sonner.hide(id);
          },
        ),
      ),
    );
  }

  void _deleteTransaction() {
    if (widget.transactionToEdit == null) return;
    final tx = widget.transactionToEdit!;
    ref.read(financialProvider.notifier).deleteTransaction(tx.id);

    final sonner = ShadSonner.of(context);
    final id = Random().nextInt(1000);
    sonner.show(
      ShadToast(
        id: id,
        title: const Text('Transaction Deleted'),
        description: Text('Removed ${tx.amount} from ${tx.categoryId}'),
        action: ShadButton.outline(
          child: const Text('Undo'),
          onPressed: () {
            ref.read(financialProvider.notifier).reinsertTransaction(tx);
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
    final isExpense = _transactionType == 'expense';
    final isEditing = widget.transactionToEdit != null;

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
          isEditing ? L10n.of(locale, 'edit_tx') : L10n.of(locale, 'add_tx'),
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
                onPressed: _deleteTransaction,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGlassCard(
                isDark,
                settings.isAmoled,
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      L10n.of(locale, 'how_much').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                        letterSpacing: 2,
                      ),
                    ),
                    TextFormField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      autofocus: !isEditing,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: isExpense
                            ? AppTheme.statusExpense
                            : AppTheme.statusIncome,
                        letterSpacing: -1,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      validator: (v) =>
                          (v == null || double.tryParse(v) == null)
                          ? 'Invalid'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionLabel('TYPE', isDark),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypePill(
                      label: L10n.of(locale, 'expense'),
                      isActive: _transactionType == 'expense',
                      activeColor: AppTheme.statusExpense,
                      isDark: isDark,
                      isAmoled: settings.isAmoled,
                      onTap: () => setState(() {
                        _transactionType = 'expense';
                        _entryType = 'default';
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypePill(
                      label: L10n.of(locale, 'income'),
                      isActive: _transactionType == 'income',
                      activeColor: AppTheme.statusIncome,
                      isDark: isDark,
                      isAmoled: settings.isAmoled,
                      onTap: () => setState(() {
                        _transactionType = 'income';
                        _entryType = 'default';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionLabel('TIMING', isDark),
              const SizedBox(height: 12),
              _buildEntryPicker(
                isDark,
                primary,
                locale,
                isExpense,
                settings.isAmoled,
              ),
              if (_entryType == 'recurring') ...[
                const SizedBox(height: 24),
                _buildSectionLabel('FREQUENCY', isDark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildSmallTextField(
                        hint: '1',
                        prefix: '${L10n.of(locale, 'every')} ',
                        isDark: isDark,
                        isAmoled: settings.isAmoled,
                        onChanged: (val) => setState(
                          () => _recurrenceInterval = int.tryParse(val) ?? 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildRecurrenceUnitPicker(
                        isDark,
                        primary,
                        locale,
                        settings.isAmoled,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              _buildSectionLabel('CATEGORY', isDark),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: AppIcons.categoryIcons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = AppIcons.categoryIcons.keys.elementAt(
                      index,
                    );
                    final icon = AppIcons.categoryIcons.values.elementAt(index);
                    final isSelected =
                        _selectedCategory.toLowerCase() ==
                        category.toLowerCase();
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory =
                            category[0].toUpperCase() + category.substring(1);
                        _selectedIcon = category;
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
              _buildSectionLabel('DETAILS', isDark),
              const SizedBox(height: 12),
              _buildGlassCard(
                isDark,
                settings.isAmoled,
                Column(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '${L10n.of(locale, 'description')} (Optional)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(Icons.notes, color: primary, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat(
                                'MMMM dd, yyyy',
                                locale,
                              ).format(_selectedDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.expand_more, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submitData,
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
                            ? L10n.of(locale, 'update_tx')
                            : L10n.of(locale, 'add_tx'))
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
        borderRadius: BorderRadius.circular(28),
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
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    );
  }

  Widget _buildTypePill({
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
    required bool isAmoled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : (isDark
                    ? (isAmoled
                          ? const Color(0xFF121212)
                          : const Color(0xFF1E293B))
                    : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? activeColor
                  : (isDark ? Colors.grey[400] : const Color(0xFF1E293B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryPicker(
    bool isDark,
    Color primary,
    String locale,
    bool isExpense,
    bool isAmoled,
  ) {
    final List<Map<String, String>> segments = isExpense
        ? [
            {'value': 'default', 'label': L10n.of(locale, 'now')},
            {'value': 'upcoming', 'label': L10n.of(locale, 'upcoming')},
            {'value': 'recurring', 'label': L10n.of(locale, 'subscription')},
          ]
        : [
            {'value': 'default', 'label': L10n.of(locale, 'now')},
            {'value': 'upcoming', 'label': L10n.of(locale, 'upcoming')},
            {'value': 'recurring', 'label': L10n.of(locale, 'salary')},
          ];
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: segments.map((seg) {
          final isActive = _entryType == seg['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _entryType = seg['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                            ? (isAmoled
                                  ? Colors.black
                                  : const Color(0xFF0F172A))
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    seg['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? primary : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecurrenceUnitPicker(
    bool isDark,
    Color primary,
    String locale,
    bool isAmoled,
  ) {
    final units = [
      {'val': 'day', 'label': L10n.of(locale, 'days')},
      {'val': 'week', 'label': L10n.of(locale, 'weeks')},
      {'val': 'month', 'label': L10n.of(locale, 'months')},
    ];
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: units.map((u) {
          final isActive = _recurrenceUnit == u['val'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recurrenceUnit = u['val']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                            ? (isAmoled
                                  ? Colors.black
                                  : const Color(0xFF0F172A))
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    u['label']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? primary : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSmallTextField({
    required String hint,
    required String prefix,
    required bool isDark,
    required bool isAmoled,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
          prefixStyle: GoogleFonts.plusJakartaSans(
            color: Colors.grey[500],
            fontSize: 13,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
