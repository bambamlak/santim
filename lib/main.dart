import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'data/providers/profile_provider.dart';
import 'data/providers/settings_provider.dart';
import 'data/services/currency_service.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final container = ProviderContainer();
  await container.read(settingsProvider.notifier).loadSettings();
  CurrencyService.syncRates();

  runApp(
    UncontrolledProviderScope(container: container, child: const SantimApp()),
  );
}

class SantimApp extends ConsumerWidget {
  const SantimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ShadApp(
      debugShowCheckedModeBanner: false,
      title: L10n.of(settings.languageCode, 'app_name'),
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      materialThemeBuilder: (context, theme) {
        if (theme.brightness == Brightness.dark) {
          return AppTheme.darkTheme(
            settings.seedColor,
            settings.languageCode,
            isAmoled: settings.isAmoled,
          );
        }
        return AppTheme.lightTheme(settings.seedColor, settings.languageCode);
      },
      themeMode: settings.themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: ref
            .watch(userProfileProvider)
            .when<Widget>(
              data: (profile) => profile == null
                  ? const OnboardingScreen(key: ValueKey('onboarding'))
                  : const HomeScreen(key: ValueKey('home')),
              loading: () => const Scaffold(
                key: ValueKey('loading'),
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Scaffold(
                key: ValueKey('error'),
                body: Center(child: Text('Error: $err')),
              ),
            ),
      ),
    );
  }
}
