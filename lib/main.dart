import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app_cubit.dart';
import 'app/ayah_app.dart';
import 'app/di.dart';
import 'features/onboarding/domain/usecases/preferences_use_cases.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Load preferences before the first frame so we route straight to the
  // right screen (no splash flicker) and pick the right locale.
  final preferences = await sl<GetUserPreferencesUseCase>()();

  runApp(
    BlocProvider(
      create: (_) => AppCubit(initial: preferences, updatePreferences: sl()),
      child: const AyahApp(),
    ),
  );
}
