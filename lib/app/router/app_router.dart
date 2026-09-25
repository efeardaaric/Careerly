import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/session/session_controller.dart';
import '../../features/analyze/presentation/analyze_screen.dart';
import '../../features/analyze/presentation/analysis_result_screen.dart';
import '../../features/analyze/presentation/processing_screen.dart';
import '../../features/analyze/presentation/sections_review_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/cv_builder/presentation/builder_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/jobs/presentation/job_match_enter_screen.dart';
import '../../features/jobs/presentation/job_match_processing_screen.dart';
import '../../features/jobs/presentation/job_match_result_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/jobs/presentation/new_job_match_screen.dart';
import '../../features/language/presentation/language_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/personalization/presentation/personalization_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const personalization = '/personalization';
  static const home = '/home';
  static const analyze = '/analyze';
  static const analyzeProcessing = '/analyze/processing';
  static const analyzeReview = '/analyze/review';
  static const analyzeResults = '/analyze/results';
  static const jobs = '/jobs';
  static const jobsNew = '/jobs/new';
  static const jobsEnter = '/jobs/enter';
  static const jobsProcessing = '/jobs/processing';
  static const jobsResults = '/jobs/results';
  static const builder = '/builder';
  static const profile = '/profile';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      final atSplash = loc == AppRoutes.splash;

      if (atSplash) return null;

      if (!session.hasLocale) {
        return loc == AppRoutes.language ? null : AppRoutes.language;
      }

      if (!session.onboardingCompleted) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (!session.isAuthenticated) {
        return loc == AppRoutes.auth ? null : AppRoutes.auth;
      }

      if (!session.personalizationCompleted) {
        return loc == AppRoutes.personalization
            ? null
            : AppRoutes.personalization;
      }

      const gateRoutes = {
        AppRoutes.language,
        AppRoutes.onboarding,
        AppRoutes.auth,
        AppRoutes.personalization,
        AppRoutes.splash,
      };
      if (gateRoutes.contains(loc)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalization,
        builder: (context, state) => const PersonalizationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.analyzeProcessing,
        builder: (context, state) => const AnalysisProcessingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.analyzeReview,
        builder: (context, state) => const SectionsReviewScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.analyzeResults,
        builder: (context, state) => const AnalysisResultScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.jobsNew,
        builder: (context, state) => const NewJobMatchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.jobsEnter,
        builder: (context, state) => const JobMatchEnterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.jobsProcessing,
        builder: (context, state) => const JobMatchProcessingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.jobsResults,
        builder: (context, state) => const JobMatchResultScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analyze,
                builder: (context, state) => const AnalyzeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                builder: (context, state) => const JobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.builder,
                builder: (context, state) => const BuilderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _SessionListenable extends ChangeNotifier {
  _SessionListenable(this._ref) {
    _sub = _ref.listen<SessionState>(sessionProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<SessionState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
