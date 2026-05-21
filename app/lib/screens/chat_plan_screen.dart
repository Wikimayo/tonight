import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../models/plan_model.dart';
import '../services/analytics_service.dart';
import '../services/chat_plan_service.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import '../services/usage_limits_service.dart';
import '../utils/tonight_page_route.dart';
import '../widgets/glass_panel.dart';
import '../widgets/tonight_app_bar.dart';
import 'plan_result_screen.dart';
import 'premium_screen.dart';

class ChatPlanScreen extends StatefulWidget {
  const ChatPlanScreen({super.key});

  @override
  State<ChatPlanScreen> createState() => _ChatPlanScreenState();
}

class _ChatPlanScreenState extends State<ChatPlanScreen> {
  final TextEditingController messageController = TextEditingController();
  final ChatPlanService _chatPlanService = const ChatPlanService();
  bool isGenerating = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, language, child) {
        final texts = AppTexts.of(language);

        return Scaffold(
          appBar: TonightAppBar(title: texts.chat),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF211229),
                  Color(0xFF0D0B11),
                  Color(0xFF08080C),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              texts.chatTitle,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    height: 1.04,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              texts.chatSubtitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.66),
                                    fontWeight: FontWeight.w700,
                                    height: 1.32,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _ChatInputCard(
                              controller: messageController,
                              enabled: !isGenerating,
                              hintText: texts.chatInputHint,
                            ),
                            const SizedBox(height: 18),
                            _ExampleChips(
                              examples: texts.chatExamples,
                              enabled: !isGenerating,
                              onSelected: _useExample,
                            ),
                            const SizedBox(height: 22),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: isGenerating
                                  ? _ChatLoadingCard(
                                      key: const ValueKey('chat-loading'),
                                      title: texts.chatLoadingTitle,
                                      message: texts.chatLoadingMessage,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('idle'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GenerateChatButton(
                      isLoading: isGenerating,
                      label: texts.generatePlan,
                      loadingLabel: texts.chatGenerating,
                      onPressed: () => _generatePlan(texts),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _useExample(String example) {
    HapticService.selectionClick();
    messageController.text = example;
    messageController.selection = TextSelection.collapsed(
      offset: example.length,
    );
    setState(() {});
  }

  Future<void> _generatePlan(AppTextValues texts) async {
    final message = messageController.text.trim();
    if (isGenerating) {
      return;
    }
    if (message.isEmpty) {
      _showSnackBar(texts.chatEmptyMessage);
      return;
    }

    FocusScope.of(context).unfocus();
    HapticService.heavyImpact();
    setState(() {
      isGenerating = true;
    });

    if (!await UsageLimitsService.canGeneratePlan()) {
      if (!mounted) {
        return;
      }

      setState(() {
        isGenerating = false;
      });

      await const AnalyticsService().logFreePlanLimitReached(
        source: 'chat_plan',
      );
      if (!mounted) {
        return;
      }

      await Navigator.of(
        context,
      ).push(tonightPageRoute<void>((_) => const PremiumScreen()));
      return;
    }

    try {
      final result = await _chatPlanService.generatePlanFromMessage(message);
      if (!mounted) {
        return;
      }

      await UsageLimitsService.registerPlanGenerated();
      await const AnalyticsService().logPlanGenerated(
        mood: result.plan.mood,
        budget: result.plan.budget,
        time: result.plan.time,
        distance: result.plan.distance,
        moment: result.plan.moment,
        weather: result.plan.weather,
      );

      if (!mounted) {
        return;
      }

      if (result.usedFallback) {
        _showSnackBar(texts.chatFallbackMessage);
      }

      HapticService.success();
      setState(() {
        isGenerating = false;
      });
      _openResult(result.plan);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(texts.chatErrorMessage);
      setState(() {
        isGenerating = false;
      });
    }
  }

  void _openResult(PlanModel plan) {
    Navigator.of(
      context,
    ).push(tonightPageRoute<void>((_) => PlanResultScreen(plan: plan)));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF17131D),
        content: Text(message),
      ),
    );
  }
}

class _ChatInputCard extends StatelessWidget {
  const _ChatInputCard({
    required this.controller,
    required this.enabled,
    required this.hintText,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 30,
      opacity: 0.045,
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 6,
        maxLines: 8,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        cursorColor: const Color(0xFFE8B66B),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.36),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.22),
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE8B66B), width: 1.3),
          ),
        ),
      ),
    );
  }
}

class _ExampleChips extends StatelessWidget {
  const _ExampleChips({
    required this.examples,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> examples;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: examples.map((example) {
        return _ExampleChip(
          label: example,
          enabled: enabled,
          onTap: () => onSelected(example),
        );
      }).toList(),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: enabled ? 0.88 : 0.40),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatLoadingCard extends StatelessWidget {
  const _ChatLoadingCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: 28,
      opacity: 0.06,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B66B).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFE8B66B),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFFE8B66B),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateChatButton extends StatelessWidget {
  const _GenerateChatButton({
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final String loadingLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isLoading ? 0.78 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFE8B66B)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8B66B).withValues(alpha: 0.30),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? Row(
                        key: const ValueKey('loading'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF100D10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loadingLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF100D10),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF100D10),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF100D10),
                            size: 21,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
