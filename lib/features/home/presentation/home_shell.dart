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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: _onTap,
          destinations: [
            _dest(
              Icons.home_outlined,
              Icons.home_rounded,
              l10n.navHome,
              idx == 0,
            ),
            _dest(
              Icons.analytics_outlined,
              Icons.analytics_rounded,
              l10n.navAnalyze,
              idx == 1,
            ),
            _dest(
              Icons.work_outline_rounded,
              Icons.work_rounded,
              l10n.navJobs,
              idx == 2,
            ),
            _dest(
              Icons.edit_note_outlined,
              Icons.edit_note_rounded,
              l10n.navBuilder,
              idx == 3,
            ),
            _dest(
              Icons.person_outline_rounded,
              Icons.person_rounded,
              l10n.navProfile,
              idx == 4,
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _dest(
    IconData icon,
    IconData selected,
    String label,
    bool isSelected,
  ) {
    return NavigationDestination(
      icon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Container(
            width: 16,
            height: 2,
            color: Colors.transparent,
          ),
        ],
      ),
      selectedIcon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected),
          const SizedBox(height: 4),
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.cobalt,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
      label: label,
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
      body: child,
    );
  }
}
