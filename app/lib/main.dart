import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_texts.dart';
import 'core/theme/app_theme.dart';
import 'screens/app_loading_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/language_service.dart';
import 'services/onboarding_service.dart';
import 'services/user_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(Firebase): `lib/firebase_options.dart` is not in this project yet.
  // Run:
  // dart pub global activate flutterfire_cli
  // flutterfire configure
  //
  // Then import `firebase_options.dart` and initialize Firebase with:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  _configureCrashReporting();
  runApp(const TonightApp());
  unawaited(_initializeFirebaseIfConfigured());
}

Future<void> _initializeFirebaseIfConfigured() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp();
  } catch (_) {
    // Firebase configuration is optional for local/mock mode. The app must keep
    // working until `flutterfire configure` adds platform options.
  }
}

void _configureCrashReporting() {
  const crashReporting = CrashReportingService();

  FlutterError.onError = (details) {
    crashReporting.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashReporting.recordFatalError(error, stackTrace);
    return false;
  };
}

class TonightApp extends StatelessWidget {
  const TonightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, language, child) {
        final texts = AppTexts.of(language);

        return MaterialApp(
          title: texts.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: child,
        );
      },
      child: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<_BootstrapResult> _bootstrapFuture = _loadInitialAppState();

  Future<_BootstrapResult> _loadInitialAppState() async {
    final results = await Future.wait<Object>([
      LanguageService.getLanguage(),
      OnboardingService.hasSeenOnboarding(),
      UserPreferencesService.getPreferences(),
    ]);

    await const AnalyticsService().logAppOpened();

    return _BootstrapResult(hasSeenOnboarding: results[1] as bool);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingScreen();
        }

        return snapshot.data!.hasSeenOnboarding
            ? const MainNavigationScreen()
            : const OnboardingScreen();
      },
    );
  }
}

class _BootstrapResult {
  const _BootstrapResult({required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;
}
