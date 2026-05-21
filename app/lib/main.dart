import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_texts.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/language_service.dart';
import 'services/onboarding_service.dart';

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
  await _initializeFirebaseIfConfigured();
  _configureCrashReporting();
  await LanguageService.getLanguage();
  await const AnalyticsService().logAppOpened();
  runApp(const TonightApp());
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

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService.hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _InitialLoadingScreen();
        }

        return snapshot.data!
            ? const MainNavigationScreen()
            : const OnboardingScreen();
      },
    );
  }
}

class _InitialLoadingScreen extends StatelessWidget {
  const _InitialLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211229), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE8B66B)),
        ),
      ),
    );
  }
}
