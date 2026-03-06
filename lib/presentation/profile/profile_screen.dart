import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/profile_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../common/widgets/local_avatar.dart';
import '../../l10n/l10n.dart';
import '../../data/services/currency_service.dart';
import '../../data/providers/financial_provider.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'ETB';
  double? _conversionResult;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convertCurrency() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      setState(() => _conversionResult = null);
      return;
    }
    final rate = await CurrencyService.getRate(_fromCurrency, _toCurrency);
    if (mounted) {
      setState(() => _conversionResult = amount * rate);
    }
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Name',
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(userProfileProvider.notifier).updateProfile(name: name);
              }
              Navigator.pop(ctx);
            },
            child: Text('SAVE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsProvider);
    final locale = settings.languageCode;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileHeaderDelegate(
              profileState: profileState,
              isDark: isDark,
              isAmoled: settings.isAmoled,
              theme: theme,
              primary: primary,
            ),
          ),

          SliverToBoxAdapter(
            child: profileState.when(
              data: (profile) {
                if (profile == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No profile found.'),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            // ── Tappable Avatar (change avatar) ──
                            GestureDetector(
                              onTap: () {
                                final nextSeed = profile.avatarSeed == 'male_avatar'
                                    ? 'female_avatar'
                                    : 'male_avatar';
                                ref.read(userProfileProvider.notifier).updateAvatar(nextSeed);
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 100, height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: primary.withValues(alpha: 0.3), width: 4),
                                      boxShadow: [
                                        BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: LocalAvatar(
                                        asset: 'lottie_assets/${profile.avatarSeed}.json',
                                        size: 100,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: primary, shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // ── Tappable Name (edit name) ──
                            GestureDetector(
                              onTap: () => _showEditNameDialog(profile.name),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22, fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildSectionLabel('APPEARANCE', isDark),
                      const SizedBox(height: 12),
                      _buildSettingsCard(isDark, [
                        _buildSettingRow(
                          icon: Icons.brightness_6_outlined,
                          iconColor: Colors.amber,
                          title: L10n.of(locale, 'theme_mode'),
                          isDark: isDark,
                          trailing: Switch.adaptive(
                            value: settings.themeMode == ThemeMode.dark,
                            onChanged: (val) => ref
                                .read(settingsProvider.notifier)
                                .setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
                            activeTrackColor: primary,
                          ),
                        ),
                        if (settings.themeMode == ThemeMode.dark) ...[
                          _buildDivider(isDark),
                          _buildSettingRow(
                            icon: Icons.dark_mode_rounded,
                            iconColor: Colors.purple,
                            title: 'AMOLED Mode',
                            isDark: isDark,
                            trailing: Switch.adaptive(
                              value: settings.isAmoled,
                              onChanged: (val) => ref.read(settingsProvider.notifier).setIsAmoled(val),
                              activeTrackColor: primary,
                            ),
                          ),
                        ],
                        _buildDivider(isDark),
                        _buildSettingRow(
                          icon: Icons.language_rounded,
                          iconColor: Colors.blue,
                          title: L10n.of(locale, 'language'),
                          isDark: isDark,
                          trailing: DropdownButton<String>(
                            value: settings.languageCode,
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem(value: 'en', child: Text('English', style: GoogleFonts.plusJakartaSans(fontSize: 14))),
                              DropdownMenuItem(value: 'am', child: Text('አማርኛ', style: GoogleFonts.plusJakartaSans(fontSize: 14))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(settingsProvider.notifier).setLanguageCode(val);
                              }
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionLabel('COLOR PALETTE', isDark),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12, runSpacing: 12,
                        children: AppTheme.palettes.entries.map((entry) {
                          final isSelected = settings.seedColor.toARGB32() == entry.value.toARGB32();
                          final col = isDark
                              ? (settings.isAmoled ? Colors.grey[900]! : Colors.grey[800]!)
                              : Colors.white;
                          return GestureDetector(
                            onTap: () => ref.read(settingsProvider.notifier).setSeedColor(entry.value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? entry.value : col,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : entry.value.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : entry.value),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      _buildSectionLabel('CURRENCY', isDark),
                      const SizedBox(height: 12),
                      _buildSettingsCard(isDark, [
                        _buildSettingRow(
                          icon: Icons.payments_outlined,
                          iconColor: Colors.green,
                          title: L10n.of(locale, 'currency'),
                          isDark: isDark,
                          trailing: DropdownButton<String>(
                            value: settings.currencyCode,
                            underline: const SizedBox(),
                            items: CurrencyService.supportedCurrencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 14))))
                                .toList(),
                            onChanged: (val) async {
                              if (val != null && val != settings.currencyCode) {
                                final oldCurrency = settings.currencyCode;
                                await ref.read(financialProvider.notifier).convertAllValues(oldCurrency, val);
                                await ref.read(settingsProvider.notifier).setCurrencyCode(val);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Converted all balances to $val')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionLabel('CONVERTER', isDark),
                      const SizedBox(height: 12),
                      _buildSettingsCard(isDark, [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                      onChanged: (_) => _convertCurrency(),
                                      decoration: InputDecoration(
                                        hintText: 'Amount', isDense: true,
                                        contentPadding: const EdgeInsets.all(12),
                                        fillColor: isDark ? Colors.black : Colors.grey[50],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  DropdownButton<String>(
                                    value: _fromCurrency, underline: const SizedBox(),
                                    items: CurrencyService.supportedCurrencies
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => setState(() { _fromCurrency = v!; _convertCurrency(); }),
                                  ),
                                  const Icon(Icons.arrow_forward, size: 16),
                                  DropdownButton<String>(
                                    value: _toCurrency, underline: const SizedBox(),
                                    items: CurrencyService.supportedCurrencies
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => setState(() { _toCurrency = v!; _convertCurrency(); }),
                                  ),
                                ],
                              ),
                              if (_conversionResult != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Result: ${_conversionResult!.toStringAsFixed(2)} $_toCurrency',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 48),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              L10n.of(locale, 'version').toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text('v1.0.4',
                                style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                            const SizedBox(height: 24),
                            Text('made by beamlak ❤️',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primary.withValues(alpha: 0.6), letterSpacing: 0.5)),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[600] : Colors.grey[400], letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (Theme.of(context).scaffoldBackgroundColor == Colors.black
                  ? const Color(0xFF121212)
                  : const Color(0xFF1E293B))
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
      trailing: trailing,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 60, endIndent: 20, color: isDark ? Colors.grey[800] : Colors.grey[100]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ProfileHeaderDelegate — avatar shows in top-right at 0 when expanded,
//   fades in as user scrolls up (opposite of home behavior).
// ═══════════════════════════════════════════════════════════════════════════════
class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AsyncValue<dynamic> profileState;
  final bool isDark;
  final bool isAmoled;
  final ThemeData theme;
  final Color primary;

  ProfileHeaderDelegate({
    required this.profileState,
    required this.isDark,
    required this.isAmoled,
    required this.theme,
    required this.primary,
  });

  @override double get minExtent => 85;
  @override double get maxExtent => 140;

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

    // Small avatar at top-right: invisible when expanded (percent=0), visible when collapsed (percent=1)
    final smallAvatarOpacity = percent;

    return ClipRect(
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
                  'Profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: fontSize, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            // Small avatar fades in on scroll
            Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: smallAvatarOpacity,
                child: profileState.maybeWhen(
                  data: (p) => p == null
                      ? const SizedBox.shrink()
                      : Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: ClipOval(
                            child: LocalAvatar(
                              asset: 'lottie_assets/${p.avatarSeed}.json',
                              size: 36,
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ProfileHeaderDelegate oldDelegate) => true;
}
