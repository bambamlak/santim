import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/providers/financial_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../l10n/l10n.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const List<Color> _categoryColors = [
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFD946EF),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialState = ref.watch(financialProvider);
    final settings = ref.watch(settingsProvider);
    final locale = settings.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: CommonHeaderDelegate(
              title: L10n.of(locale, 'insights'),
              isDark: isDark,
              isAmoled: settings.isAmoled,
              theme: theme,
              trailing: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? (settings.isAmoled ? const Color(0xFF121212) : const Color(0xFF1E293B))
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Icon(Icons.calendar_today, size: 18,
                    color: isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ),

          financialState.when(
            data: (data) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSpendingOverviewCard(data, theme, locale, settings.currencyCode, isDark, primary),
                    const SizedBox(height: 32),
                    Text(
                      L10n.of(locale, 'category_breakdown'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryBreakdown(data, theme, locale, settings.currencyCode, isDark, primary),
                    const SizedBox(height: 32),
                    Text(
                      'Balance Evolution',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hold on the chart to scrub through the month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BalanceTrendCard(data: data, isDark: isDark, primary: primary, currency: settings.currencyCode),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverviewCard(
    FinancialState data, ThemeData theme, String locale, String currency, bool isDark, Color primary,
  ) {
    final now = DateTime.now();
    final monthSpent = data.allTransactions
        .where((t) => t.type == 'expense' && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
    final cardColor = isDark
        ? (theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF121212) : const Color(0xFF1E293B))
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF1E293B).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spent This Month', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: '${_formatNumber(monthSpent)} ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                TextSpan(text: currency,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              ]),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[100]),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MONTH TXN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[400], letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      data.allTransactions.where((t) => t.date.year == now.year && t.date.month == now.month).length.toString(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ],
                )),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('MOST SPENT ON', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[400], letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(_getHighestCategory(data),
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: primary)),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final formatted = n.toStringAsFixed(0);
      final chars = formatted.split('');
      final buffer = StringBuffer();
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && (chars.length - i) % 3 == 0) buffer.write(',');
        buffer.write(chars[i]);
      }
      return buffer.toString();
    }
    return n.toStringAsFixed(0);
  }

  String _getHighestCategory(FinancialState data) {
    final now = DateTime.now();
    final monthTxs = data.allTransactions.where(
        (t) => t.type == 'expense' && t.date.year == now.year && t.date.month == now.month);
    if (monthTxs.isEmpty) return 'N/A';
    final Map<String, double> totals = {};
    for (var tx in monthTxs) {
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
    }
    if (totals.isEmpty) return 'N/A';
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Widget _buildCategoryBreakdown(
    FinancialState data, ThemeData theme, String locale, String currency, bool isDark, Color primary,
  ) {
    final now = DateTime.now();
    final expenses = data.allTransactions
        .where((t) => t.type == 'expense' && t.date.year == now.year && t.date.month == now.month)
        .toList();
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('No expense data for this month.',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14)),
        ),
      );
    }
    final Map<String, double> categoryMap = {};
    for (var tx in expenses) {
      categoryMap[tx.categoryId] = (categoryMap[tx.categoryId] ?? 0) + tx.amount;
    }
    final total = categoryMap.values.fold(0.0, (sum, v) => sum + v);
    final sortedCategories = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topPercent = sortedCategories.isNotEmpty
        ? (sortedCategories.first.value / total * 100).toStringAsFixed(1) : '0';

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 60,
                sections: sortedCategories.asMap().entries.map((entry) =>
                    PieChartSectionData(
                      color: _categoryColors[entry.key % _categoryColors.length],
                      value: entry.value.value,
                      title: '',
                      radius: 35,
                    )).toList(),
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$topPercent%', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('Primary', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[400], letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...sortedCategories.asMap().entries.map((entry) {
          final percentage = (entry.value.value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColors[entry.key % _categoryColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.value.key,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                Text('${_formatNumber(entry.value.value)} $currency',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Text('$percentage%', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Interactive Balance Trend Card ──────────────────────────────────────────
class _BalanceTrendCard extends StatefulWidget {
  final FinancialState data;
  final bool isDark;
  final Color primary;
  final String currency;

  const _BalanceTrendCard({
    required this.data,
    required this.isDark,
    required this.primary,
    required this.currency,
  });

  @override
  State<_BalanceTrendCard> createState() => _BalanceTrendCardState();
}

class _BalanceTrendCardState extends State<_BalanceTrendCard> {
  int? _touchedDay;
  double? _touchedBalance;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDay = now.day;
    final dailyBalances = widget.data.dailyBalances;

    if (dailyBalances.isEmpty) {
      return _buildEmptyCard();
    }

    // Build spots from daily balance map (day 0 = start of month)
    final List<FlSpot> spots = [];
    for (int d = 0; d <= todayDay; d++) {
      if (dailyBalances.containsKey(d)) {
        spots.add(FlSpot(d.toDouble(), dailyBalances[d]!));
      }
    }

    if (spots.isEmpty) return _buildEmptyCard();

    // Dynamic Y scaling — zoom into actual range for premium feel
    final values = spots.map((s) => s.y).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final buffer = range < 1 ? 100.0 : range * 0.12;

    final graphBg = widget.isDark
        ? (Theme.of(context).scaffoldBackgroundColor == Colors.black
              ? const Color(0xFF121212) : const Color(0xFF1E293B))
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: graphBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF1E293B).withValues(alpha: 0.05),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrub tooltip display
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _touchedDay != null
                  ? Padding(
                      key: ValueKey(_touchedDay),
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _touchedDay == 0
                                ? 'Month Start'
                                : DateFormat('MMM d').format(DateTime(now.year, now.month, _touchedDay!)),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            '${_touchedBalance?.toStringAsFixed(2) ?? '—'} ${widget.currency}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      key: const ValueKey('default'),
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Balance',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                          Text(
                            '${widget.data.totalBalance.toStringAsFixed(2)} ${widget.currency}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            AspectRatio(
              aspectRatio: 1.8,
              child: LineChart(
                LineChartData(
                  // ── Scrubbing interaction ──
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      final spot = response?.lineBarSpots?.firstOrNull;
                      if (spot != null && (event is FlPointerHoverEvent || event is FlPanUpdateEvent || event is FlLongPressStart || event is FlLongPressMoveUpdate)) {
                        setState(() {
                          _touchedDay = spot.x.toInt();
                          _touchedBalance = spot.y;
                        });
                      } else if (event is FlPanEndEvent || event is FlLongPressEnd || event is FlTapUpEvent) {
                        setState(() {
                          _touchedDay = null;
                          _touchedBalance = null;
                        });
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (_) => [],  // We use the header display instead
                    ),
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((idx) => TouchedSpotIndicatorData(
                        FlLine(color: widget.primary.withValues(alpha: 0.4), strokeWidth: 1.5, dashArray: [4, 4]),
                        FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(radius: 5, color: widget.primary, strokeWidth: 2, strokeColor: Colors.white)),
                      )).toList();
                    },
                  ),

                  // ── Grid — very faint ──
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: widget.primary.withValues(alpha: 0.04),
                      strokeWidth: 1,
                    ),
                  ),

                  // ── Axis labels — milestones only ──
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: (maxVal - minVal) > 0 ? (maxVal - minVal) : 1,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _compact(value),
                                style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                                textAlign: TextAlign.right,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final d = value.toInt();
                          // Show only Day 1, Day 15, Day 30 (and today)
                          final milestones = {1, 15, 30, todayDay};
                          if (milestones.contains(d) && d >= 0 && d <= todayDay) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                d == todayDay ? 'Today' : '$d',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: d == todayDay ? widget.primary : Colors.grey[400],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),

                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: todayDay.toDouble(),
                  minY: minVal - buffer,
                  maxY: maxVal + buffer,

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,              // Bézier curves = premium
                      curveSmoothness: 0.35,
                      color: widget.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            widget.primary.withValues(alpha: 0.22),
                            widget.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compact(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      child: Center(
        child: Text('No transactions yet this month.',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14)),
      ),
    );
  }
}

// ─── CommonHeaderDelegate ────────────────────────────────────────────────────
class CommonHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final bool isDark;
  final bool isAmoled;
  final ThemeData theme;
  final Widget? trailing;

  CommonHeaderDelegate({
    required this.title,
    required this.isDark,
    required this.isAmoled,
    required this.theme,
    this.trailing,
  });

  @override
  double get minExtent => 85;
  @override
  double get maxExtent => 140;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topPadding = MediaQuery.of(context).padding.top;
    final percent = (shrinkOffset / maxExtent).clamp(0.0, 1.0);

    final barColor = Color.lerp(
      theme.scaffoldBackgroundColor,
      isDark ? (isAmoled ? Colors.black : const Color(0xFF0F172A)) : Colors.white,
      percent,
    );
    final fontSize = (36 - (percent * 12)).toDouble();

    return ClipRect(            // ← fixes the clipping bug here too
      child: Container(
        color: barColor,
        padding: EdgeInsets.fromLTRB(24, topPadding + 10, 24, 0),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: (1 - percent) * 30),
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: fontSize, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CommonHeaderDelegate oldDelegate) => true;
}
