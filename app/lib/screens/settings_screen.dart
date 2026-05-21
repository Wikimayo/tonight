import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_texts.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/local_plan_storage.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../services/premium_service.dart';
import '../services/user_preferences_service.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/mood_chip.dart';
import '../widgets/tonight_app_bar.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBackButton
          ? TonightAppBar(
              title: AppTexts.of(LanguageService.currentLanguage).settings,
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211229), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showBackButton) const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: LanguageService.languageNotifier,
                  builder: (context, language, child) {
                    return Text(
                      AppTexts.of(language).settings,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Controla tus datos locales y la experiencia inicial.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PreferencesSection(),
                        const SizedBox(height: 26),
                        ValueListenableBuilder<String>(
                          valueListenable: LanguageService.languageNotifier,
                          builder: (context, language, child) {
                            final texts = AppTexts.of(language);

                            return Column(
                              children: [
                                _LanguageSettingsSection(texts: texts),
                                const SizedBox(height: 26),
                                _NotificationSettingsSection(
                                  title: texts.notifications,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        _SettingsSection(
                          title: 'Datos',
                          icon: Icons.storage_rounded,
                          children: [
                            _SettingsAction(
                              icon: Icons.history_rounded,
                              label: 'Borrar historial',
                              isDestructive: true,
                              onPressed: () => _confirmAndRun(
                                context,
                                title: 'Borrar historial',
                                message:
                                    'Se eliminarán todos tus planes recientes.',
                                completedMessage: 'Historial borrado',
                                hasData: () async =>
                                    (await LocalPlanStorage.getHistory())
                                        .isNotEmpty,
                                action: LocalPlanStorage.clearHistory,
                              ),
                            ),
                            _SettingsAction(
                              icon: Icons.favorite_rounded,
                              label: 'Borrar favoritos',
                              isDestructive: true,
                              onPressed: () => _confirmAndRun(
                                context,
                                title: 'Borrar favoritos',
                                message:
                                    'Se eliminarán todos tus planes favoritos.',
                                completedMessage: 'Favoritos borrados',
                                hasData: () async =>
                                    (await LocalPlanStorage.getFavorites())
                                        .isNotEmpty,
                                action: LocalPlanStorage.clearFavorites,
                              ),
                            ),
                            _SettingsAction(
                              icon: Icons.delete_sweep_rounded,
                              label: 'Borrar todo',
                              isDestructive: true,
                              onPressed: () => _confirmAndRun(
                                context,
                                title: 'Borrar todo',
                                message:
                                    'Se eliminarán historial y favoritos de este dispositivo.',
                                completedMessage: 'Datos borrados',
                                hasData: _hasAnySavedData,
                                action: LocalPlanStorage.clear,
                              ),
                            ),
                          ],
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 26),
                          const _PremiumDebugSection(),
                        ],
                        const SizedBox(height: 26),
                        _SettingsSection(
                          title: 'App',
                          icon: Icons.auto_awesome_rounded,
                          children: [
                            const _VersionRow(),
                            _SettingsAction(
                              icon: Icons.replay_rounded,
                              label: 'Ver onboarding de nuevo',
                              onPressed: () => _showOnboardingAgain(context),
                            ),
                            if (kDebugMode)
                              _SettingsAction(
                                icon: Icons.bug_report_rounded,
                                label: 'Probar Crashlytics (debug/test)',
                                onPressed: () => _testCrashlytics(context),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required String completedMessage,
    required Future<bool> Function() hasData,
    required Future<void> Function() action,
  }) async {
    HapticService.mediumImpact();
    final canDelete = await hasData();
    if (!context.mounted) {
      return;
    }

    if (!canDelete) {
      _showSnackBar(context, 'No hay datos que borrar.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17131D),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    HapticService.heavyImpact();
    await action();
    if (!context.mounted) {
      return;
    }

    _showSnackBar(context, completedMessage);
  }

  Future<bool> _hasAnySavedData() async {
    final results = await Future.wait([
      LocalPlanStorage.getHistory(),
      LocalPlanStorage.getFavorites(),
    ]);

    return results.any((plans) => plans.isNotEmpty);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(message),
      ),
    );
  }

  Future<void> _showOnboardingAgain(BuildContext context) async {
    await OnboardingService.reset();
    if (!context.mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(tonightPageRoute<void>((_) => const OnboardingScreen()));
  }

  Future<void> _testCrashlytics(BuildContext context) async {
    await const CrashReportingService().log(
      'Tonight Crashlytics debug/test button tapped',
    );
    await const CrashReportingService().recordError(
      StateError('Tonight Crashlytics debug/test error'),
      StackTrace.current,
    );

    if (!context.mounted) {
      return;
    }

    _showSnackBar(context, 'Error de prueba registrado en Crashlytics');
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 30,
      opacity: 0.045,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8B66B).withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFE8B66B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PreferencesSection extends StatefulWidget {
  const _PreferencesSection();

  @override
  State<_PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<_PreferencesSection> {
  static const List<String> budgets = ['Gratis', '€', '€€', '€€€'];
  static const List<String> times = ['1h', '2h', '3h', 'Toda la noche'];
  static const List<String> distances = ['Cerca', 'Media', 'Me da igual'];

  final TextEditingController locationController = TextEditingController();
  late Future<UserPreferences> preferencesFuture;
  String selectedBudget = '€€';
  String selectedTime = '2h';
  String selectedDistance = 'Media';

  @override
  void initState() {
    super.initState();
    preferencesFuture = _loadPreferences();
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  Future<UserPreferences> _loadPreferences() async {
    final preferences = await UserPreferencesService.getPreferences();
    locationController.text = preferences.defaultLocation ?? '';
    selectedBudget = _optionOrFallback(
      preferences.defaultBudget,
      budgets,
      selectedBudget,
    );
    selectedTime = _optionOrFallback(
      preferences.defaultTime,
      times,
      selectedTime,
    );
    selectedDistance = _optionOrFallback(
      preferences.defaultDistance,
      distances,
      selectedDistance,
    );

    return preferences;
  }

  String _optionOrFallback(
    String? value,
    List<String> options,
    String fallback,
  ) {
    final trimmedValue = value?.trim();
    if (trimmedValue != null && options.contains(trimmedValue)) {
      return trimmedValue;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserPreferences>(
      future: preferencesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const GlassPanel(
            padding: EdgeInsets.all(20),
            borderRadius: 30,
            opacity: 0.045,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE8B66B)),
            ),
          );
        }

        return _SettingsSection(
          title: 'Preferencias',
          icon: Icons.tune_rounded,
          children: [
            _PreferenceLocationField(
              controller: locationController,
              onSave: _saveLocation,
            ),
            const SizedBox(height: 18),
            _PreferenceChipRow(
              title: 'Presupuesto favorito',
              options: budgets,
              selectedOption: selectedBudget,
              onSelected: (value) async {
                setState(() {
                  selectedBudget = value;
                });
                await UserPreferencesService.saveDefaultBudget(value);
                _showSavedMessage();
              },
            ),
            const SizedBox(height: 18),
            _PreferenceChipRow(
              title: 'Tiempo favorito',
              options: times,
              selectedOption: selectedTime,
              onSelected: (value) async {
                setState(() {
                  selectedTime = value;
                });
                await UserPreferencesService.saveDefaultTime(value);
                _showSavedMessage();
              },
            ),
            const SizedBox(height: 18),
            _PreferenceChipRow(
              title: 'Distancia favorita',
              options: distances,
              selectedOption: selectedDistance,
              onSelected: (value) async {
                setState(() {
                  selectedDistance = value;
                });
                await UserPreferencesService.saveDefaultDistance(value);
                _showSavedMessage();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocation() async {
    await UserPreferencesService.saveDefaultLocation(locationController.text);
    if (!mounted) {
      return;
    }

    _showSavedMessage();
  }

  void _showSavedMessage() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17131D),
        content: Text('Preferencias guardadas'),
      ),
    );
  }
}

class _PremiumDebugSection extends StatefulWidget {
  const _PremiumDebugSection();

  @override
  State<_PremiumDebugSection> createState() => _PremiumDebugSectionState();
}

class _PremiumDebugSectionState extends State<_PremiumDebugSection> {
  late Future<bool> premiumFuture;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    premiumFuture = _loadPremiumState();
  }

  Future<bool> _loadPremiumState() async {
    final enabled = await PremiumService.isPremium();
    isPremium = enabled;
    return enabled;
  }

  Future<void> _setPremiumMock(bool value) async {
    HapticService.mediumImpact();
    setState(() {
      isPremium = value;
    });
    await PremiumService.setPremiumMock(value);
    if (value) {
      await const AnalyticsService().logPremiumMockEnabled();
    } else {
      await const AnalyticsService().logPremiumMockDisabled();
    }
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(
          value ? 'Premium mock activado' : 'Premium mock desactivado',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: premiumFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const GlassPanel(
            padding: EdgeInsets.all(20),
            borderRadius: 30,
            opacity: 0.045,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE8B66B)),
            ),
          );
        }

        return _SettingsSection(
          title: 'Debug',
          icon: Icons.developer_mode_rounded,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFE8B66B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium mock',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ignora el límite gratuito mientras esté activo.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isPremium,
                    activeThumbColor: const Color(0xFFE8B66B),
                    onChanged: _setPremiumMock,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageSettingsSection extends StatefulWidget {
  const _LanguageSettingsSection({required this.texts});

  final AppTextValues texts;

  @override
  State<_LanguageSettingsSection> createState() =>
      _LanguageSettingsSectionState();
}

class _LanguageSettingsSectionState extends State<_LanguageSettingsSection> {
  String selectedLanguage = LanguageService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await LanguageService.getLanguage();
    if (!mounted) {
      return;
    }

    setState(() {
      selectedLanguage = language;
    });
  }

  Future<void> _setLanguage(String languageCode) async {
    if (languageCode == selectedLanguage) {
      return;
    }

    HapticService.selectionClick();
    await LanguageService.setLanguage(languageCode);
    if (!mounted) {
      return;
    }

    setState(() {
      selectedLanguage = languageCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(
          languageCode == LanguageService.english
              ? 'Language updated'
              : 'Idioma actualizado',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: widget.texts.language,
      icon: Icons.language_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: MoodChip(
                label: 'Español',
                isSelected: selectedLanguage == LanguageService.spanish,
                onTap: () => _setLanguage(LanguageService.spanish),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MoodChip(
                label: 'English',
                isSelected: selectedLanguage == LanguageService.english,
                onTap: () => _setLanguage(LanguageService.english),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationSettingsSection extends StatefulWidget {
  const _NotificationSettingsSection({required this.title});

  final String title;

  @override
  State<_NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<_NotificationSettingsSection> {
  late Future<bool> notificationsFuture;
  bool isEnabled = false;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    notificationsFuture = _loadNotificationState();
  }

  Future<bool> _loadNotificationState() async {
    final enabled = await NotificationService.isSmartNotificationsEnabled();
    isEnabled = enabled;
    return enabled;
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    if (isUpdating) {
      return;
    }

    HapticService.mediumImpact();
    setState(() {
      isEnabled = value;
      isUpdating = true;
    });

    if (value) {
      final scheduled = await NotificationService.scheduleSmartNotifications();
      if (!mounted) {
        return;
      }

      if (scheduled) {
        await const AnalyticsService().logSmartNotificationsEnabled();
        _showSnackBar('Notificaciones inteligentes activadas');
      } else {
        setState(() {
          isEnabled = false;
        });
        _showSnackBar('No se pudieron activar las notificaciones.');
      }
    } else {
      await NotificationService.cancelSmartNotifications();
      await const AnalyticsService().logSmartNotificationsDisabled();
      if (!mounted) {
        return;
      }

      _showSnackBar('Notificaciones inteligentes desactivadas');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isUpdating = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: notificationsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const GlassPanel(
            padding: EdgeInsets.all(20),
            borderRadius: 30,
            opacity: 0.045,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE8B66B)),
            ),
          );
        }

        return _SettingsSection(
          title: widget.title,
          icon: Icons.notifications_active_rounded,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Color(0xFFE8B66B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificaciones inteligentes',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recordatorios locales para viernes, sábado y domingo.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  isUpdating
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFFE8B66B),
                          ),
                        )
                      : Switch(
                          value: isEnabled,
                          activeThumbColor: const Color(0xFFE8B66B),
                          onChanged: _setNotificationsEnabled,
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreferenceLocationField extends StatelessWidget {
  const _PreferenceLocationField({
    required this.controller,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ciudad habitual',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          cursorColor: const Color(0xFFE8B66B),
          decoration: InputDecoration(
            hintText: 'Madrid, Barcelona, Valencia...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.24),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFE8B66B),
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PreferenceSaveButton(label: 'Guardar ciudad', onTap: onSave),
      ],
    );
  }
}

class _PreferenceChipRow extends StatelessWidget {
  const _PreferenceChipRow({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: options.map((option) {
            return MoodChip(
              label: option,
              isSelected: selectedOption == option,
              onTap: () => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PreferenceSaveButton extends StatelessWidget {
  const _PreferenceSaveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8B66B).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFFF8F8F)
        : const Color(0xFFE8B66B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFE8B66B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Versión 0.1.0',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
