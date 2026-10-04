import 'package:flutter/material.dart';
import 'package:careerly/app/localization/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final idx = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 66,
                backgroundColor: AppColors.inkNavy,
                indicatorColor: AppColors.brandYellow.withValues(alpha: 0.14),
                labelTextStyle: WidgetStateProperty.resolveWith(
                  (states) => TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.brandYellow
                        : Colors.white70,
                  ),
                ),
                iconTheme: WidgetStateProperty.resolveWith(
                  (states) => IconThemeData(
                    size: 22,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.brandYellow
                        : Colors.white70,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: idx,
                onDestinationSelected: _onTap,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: l10n.navHome,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.analytics_outlined),
                    selectedIcon: const Icon(Icons.analytics_rounded),
                    label: l10n.navAnalyze,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.work_outline_rounded),
                    selectedIcon: const Icon(Icons.work_rounded),
                    label: l10n.navJobs,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.edit_note_outlined),
                    selectedIcon: const Icon(Icons.edit_note_rounded),
                    label: l10n.navBuilder,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: l10n.navProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft atmosphere scaffold — cream/ice wash, no generic gray app bar wash.
class CareerlyScaffold extends StatelessWidget {
  const CareerlyScaffold({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
  });

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final body = title == null
        ? SafeArea(bottom: false, child: child)
        : SafeArea(top: false, bottom: false, child: child);
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
              backgroundColor: backgroundColor ?? AppColors.background,
            ),
      body: body,
    );
  }
}
