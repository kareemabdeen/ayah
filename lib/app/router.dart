import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/memorization/presentation/cubit/memorization_cubit.dart';
import '../features/memorization/presentation/pages/memorization_page.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/pages/settings_page.dart';
import '../features/progress/presentation/cubit/progress_cubit.dart';
import '../features/progress/presentation/cubit/surah_progress_cubit.dart';
import '../features/progress/presentation/pages/progress_page.dart';
import '../features/progress/presentation/pages/surah_progress_page.dart';
import '../features/review/presentation/cubit/review_cubit.dart';
import '../features/review/presentation/pages/review_page.dart';
import 'di.dart';

abstract final class Routes {
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const memorize = 'memorize';
  static const review = 'review';
  static const progress = 'progress';
  static const surah = 'surah';
  static const settings = 'settings';
}

/// Arguments for [Routes.memorize].
final class MemorizeArgs {
  const MemorizeArgs({this.extraVerse = false});
  final bool extraVerse;
}

/// Arguments for [Routes.review]. `surahTestId` switches to Full Surah Test.
final class ReviewArgs {
  const ReviewArgs({this.surahTestId});
  final int? surahTestId;
}

/// Named-route table. Route names have no leading "/" on purpose: Flutter
/// splits a "/a" initialRoute into ["/", "/a"] and would stack two pages.
/// Each route owns its cubit's lifetime via BlocProvider,
/// so screens are isolated and cubits are disposed on pop.
/// Swapping to go_router later only touches this file.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      Routes.onboarding => BlocProvider(create: (_) => sl<OnboardingCubit>(), child: const OnboardingPage()),
      Routes.memorize => BlocProvider(
          create: (_) {
            final args = settings.arguments as MemorizeArgs? ?? const MemorizeArgs();
            return sl<MemorizationCubit>()..start(extraVerse: args.extraVerse);
          },
          child: const MemorizationPage(),
        ),
      Routes.review => BlocProvider(
          create: (_) {
            final args = settings.arguments as ReviewArgs? ?? const ReviewArgs();
            return sl<ReviewCubit>()..load(surahTestId: args.surahTestId);
          },
          child: const ReviewPage(),
        ),
      Routes.progress => BlocProvider(create: (_) => sl<ProgressCubit>()..load(), child: const ProgressPage()),
      Routes.surah => BlocProvider(
          create: (_) => sl<SurahProgressCubit>()..load(settings.arguments! as int),
          child: const SurahProgressPage(),
        ),
      Routes.settings => const SettingsPage(),
      _ => BlocProvider(create: (_) => sl<HomeCubit>()..load(), child: const HomePage()),
    };
    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
