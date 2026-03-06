import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/providers/financial_provider.dart';
import '../../../data/providers/profile_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/icons.dart';
import '../../budget/add_budget_screen.dart';
import '../../../domain/models/transaction.dart' as t;
import '../../common/widgets/local_avatar.dart';
import '../../../l10n/l10n.dart';
import '../../../data/providers/settings_provider.dart';
import '../../transaction/add_transaction_screen.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    final financialState = ref.watch(financialProvider);
    final profileState = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsProvider);
    final locale = settings.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: HomeHeaderDelegate(
            financialState: financialState,
            profileState: profileState,
            settings: settings,
            theme: theme,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Budgets Section ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              L10n.of(locale, 'budgets'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildBudgetsList(
              financialState,
              theme,
              locale,
              settings.currencyCode,
              theme.colorScheme.primary,
              isDark,
              settings.isAmoled,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Recent Transactions Section ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Text(
              L10n.of(locale, 'transactions'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        _buildGroupedTransactionsSliver(
          financialState,
          theme,
          locale,
          theme.colorScheme.primary,
          isDark,
          settings.isAmoled,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildBudgetsList(
    AsyncValue<FinancialState> financialState,
    ThemeData theme,
    String locale,
    String currencyCode,
    Color primary,
    bool isDark,
    bool isAmoled,
  ) {
    return financialState.when(
      data: (data) {
        if (data.budgets.isEmpty) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    L10n.of(locale, 'add_budget'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.budgets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildBudgetCard(
              data.budgets[index],
              data.allTransactions,
              theme,
              currencyCode,
              primary,
              isDark,
              isAmoled,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, a) => const SizedBox.shrink(),
    );
  }

  Widget _buildBudgetCard(
    dynamic budget,
    List<t.Transaction> txs,
    ThemeData theme,
    String currencyCode,
    Color primary,
    bool isDark,
    bool isAmoled,
  ) {
    final now = DateTime.now();
    final spent = txs
        .where(
          (tx) =>
              tx.categoryId == budget.categoryId &&
              tx.type == 'expense' &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final progress = (spent / budget.amountLimit).clamp(0.0, 1.0);
    final isReserve = (budget.type ?? 'reserve') == 'reserve';
    final typeColor = isReserve
        ? const Color(0xFF10B981)
        : theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddBudgetScreen(budgetToEdit: budget),
        ),
      ),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(AppIcons.fromName(budget.icon), size: 14, color: typeColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    budget.categoryId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              isReserve ? '🏺 Saving' : '📦 Budget',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: typeColor.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${budget.amountLimit.toStringAsFixed(0)} $currencyCode',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ShadProgress(
                value: progress,
                color: progress > 0.9 ? AppTheme.statusExpense : typeColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent ${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                if (isReserve)
                  Text(
                    '🔒',
                    style: const TextStyle(fontSize: 9),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionsSliver(
    AsyncValue<FinancialState> financialState,
    ThemeData theme,
    String locale,
    Color primary,
    bool isDark,
    bool isAmoled,
  ) {
    return financialState.when(
      data: (data) {
        if (data.recentTransactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isAmoled
                            ? const Color(0xFF121212)
                            : const Color(0xFF1E293B).withValues(alpha: 0.7))
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long, color: Colors.grey[400], size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.of(locale, 'add_tx'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6, shadowColor: primary.withValues(alpha: 0.3),
                      ),
                      child: Text(L10n.of(locale, 'add_tx'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final Map<String, List<t.Transaction>> grouped = {};
        for (var tx in data.recentTransactions) {
          final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
          String dayLabel = txDate == today
              ? 'Today'
              : (txDate == yesterday
                    ? 'Yesterday'
                    : DateFormat('EEE, MMM d').format(tx.date));
          grouped.putIfAbsent(dayLabel, () => []).add(tx);
        }

        final List<Widget> sliverItems = [];
        grouped.forEach((day, txs) {
          sliverItems.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                day.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey[400], letterSpacing: 1.5,
                ),
              ),
            ),
          );
          for (var tx in txs) {
            sliverItems.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: _buildTransactionTile(tx, theme, locale, primary, isDark, isAmoled),
              ),
            );
          }
        });

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => sliverItems[index],
            childCount: sliverItems.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
    );
  }

  Widget _buildTransactionTile(
    t.Transaction tx,
    ThemeData theme,
    String locale,
    Color primary,
    bool isDark,
    bool isAmoled,
  ) {
    final isIncome = tx.type == 'income';
    final cardColor = isDark
        ? (isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
        : Colors.white;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddTransactionScreen(transactionToEdit: tx),
        ),
      ),
      onLongPress: () => _showDeleteDialog(tx),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isIncome
                    ? AppTheme.statusIncome.withValues(alpha: 0.1)
                    : AppTheme.statusExpense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isIncome
                    ? AppIcons.insightsActive
                    : (tx.icon != null
                          ? AppIcons.fromName(tx.icon)
                          : AppIcons.insightsInactive),
                color: isIncome ? AppTheme.statusIncome : AppTheme.statusExpense,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description ?? L10n.of(locale, 'other'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tx.categoryId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isIncome ? AppTheme.statusIncome : AppTheme.statusExpense,
                  ),
                ),
                if (tx.entryType == 'upcoming')
                  Text('upcoming', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.orange[400]))
                else if (tx.entryType == 'recurring')
                  Text('recurring', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.blue[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(t.Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to remove this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(financialProvider.notifier).deleteTransaction(tx.id);
              Navigator.pop(context);
              _showUndoToast(tx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUndoToast(t.Transaction tx) {
    final sonner = ShadSonner.of(context);
    final id = math.Random().nextInt(1000);
    sonner.show(
      ShadToast(
        id: id,
        title: const Text('Transaction Deleted'),
        description: Text('Transaction for ${tx.amount} removed'),
        action: ShadButton.outline(
          child: const Text('Undo'),
          onPressed: () {
            ref.read(financialProvider.notifier).reinsertTransaction(tx);
            sonner.hide(id);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HomeHeaderDelegate
// ═══════════════════════════════════════════════════════════════════════════════
class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AsyncValue<FinancialState> financialState;
  final AsyncValue<dynamic> profileState;
  final AppSettings settings;
  final ThemeData theme;

  HomeHeaderDelegate({
    required this.financialState,
    required this.profileState,
    required this.settings,
    required this.theme,
  });

  @override
  double get minExtent => 85;
  @override
  double get maxExtent => 350;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final locale = settings.languageCode;

    final barColor = Color.lerp(
      theme.scaffoldBackgroundColor,
      isDark
          ? (settings.isAmoled ? Colors.black : const Color(0xFF0F172A))
          : Colors.white,
      t,
    );

    final avatarSize = _lerp(56, 40, t);
    final welcomeOpacity = (1 - t * 3).clamp(0.0, 1.0);
    final santimOpacity = ((t - 0.5) * 2).clamp(0.0, 1.0);

    return ClipRect(          // ← fixes clipping bug: hides overflow
      child: Container(
        color: barColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Expanded Content ──
            Positioned(
              top: topPadding + 24,
              left: 24,
              right: 24,
              child: Opacity(
                opacity: welcomeOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale == 'am' ? 'እንደምን አደርክ(ሽ),' : 'Good Morning,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    profileState.maybeWhen(
                      data: (p) => Text(
                        p?.name ?? 'Guest',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    _buildSafeToSpendCard(isDark, primary, locale),
                  ],
                ),
              ),
            ),

            // ── Collapsed Title ──
            Positioned(
              top: topPadding + 22,
              left: 24,
              child: Opacity(
                opacity: santimOpacity,
                child: Text(
                  'Santim',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // ── Pinned Avatar (always visible in top-right) ──
            Positioned(
              top: topPadding + _lerp(24, 18, t),
              right: 24,
              child: profileState.maybeWhen(
                data: (p) => Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_lerp(18, 12, t)),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_lerp(16, 10, t)),
                    child: LocalAvatar(
                      asset: 'lottie_assets/${p?.avatarSeed ?? "male_avatar"}.json',
                      size: avatarSize,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeToSpendCard(bool isDark, Color primary, String locale) {
    final now = DateTime.now();
    final dend = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (dend - now.day) + 1;
    final cardColor = isDark
        ? (settings.isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
        : Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.2),
            blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: financialState.when(
          data: (data) {
            final isStsNegative = data.safeToSpend < 0;
            final stsColor = isStsNegative ? AppTheme.statusExpense : (isDark ? Colors.white : const Color(0xFF0F172A));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isStsNegative ? Icons.warning_rounded : Icons.check_circle,
                      color: isStsNegative ? AppTheme.statusExpense : primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      L10n.of(locale, 'safe_to_spend').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isStsNegative ? AppTheme.statusExpense : primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Daily Allowance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${data.dailyAllowance.toStringAsFixed(0)} ${settings.currencyCode}/day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w700, color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${data.safeToSpend.abs().toStringAsFixed(0)} ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 44, fontWeight: FontWeight.w700,
                          color: stsColor, letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: settings.currencyCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, fontWeight: FontWeight.w500, color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isStsNegative)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Over budget — consider pulling from a Budget Jar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppTheme.statusExpense, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                // Three-column breakdown
                Row(
                  children: [
                    _statPill('Balance', data.totalBalance, settings.currencyCode, isDark),
                    _dividerV(),
                    _statPill('Saved 🔒', data.savingJarAllocations, settings.currencyCode, isDark),
                    _dividerV(),
                    _statPill('Reserved 📦', data.budgetJarRemaining, settings.currencyCode, isDark),
                  ],
                ),
                const SizedBox(height: 12),
                // Days remaining progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysRemaining days left in month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (data.upcomingExpenses > 0)
                      Text(
                        'Upcoming: ${data.upcomingExpenses.toStringAsFixed(0)} ${settings.currencyCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: AppTheme.statusExpense.withValues(alpha: 0.8), fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _statPill(String label, double value, String currency, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(0),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _dividerV() {
    return Container(
      width: 1, height: 28,
      color: Colors.grey.withValues(alpha: 0.15),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRebuild(covariant HomeHeaderDelegate oldDelegate) => true;
}
