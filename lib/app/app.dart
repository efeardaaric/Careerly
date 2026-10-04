import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import 'router/app_router.dart';
import 'session/session_controller.dart';
import 'theme/app_theme.dart';

class CareerlyApp extends ConsumerWidget {
  const CareerlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final session = ref.watch(sessionProvider);
    final theme = buildCareerlyTheme();
    final darkTheme = buildCareerlyDarkTheme();

    return MaterialApp.router(
      title: 'Careerly AI',
      // The dev environment is still selected through AppConfig, but the
      // framework ribbon must not compete with the product brand in previews.
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      // Reference identity uses light document surfaces consistently.
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: session.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
