import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';

import '../core/config/app_config.dart';
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

    return MaterialApp.router(
      title: 'Careerly AI',
      debugShowCheckedModeBanner: AppConfig.instance.isDev,
      theme: theme,
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
