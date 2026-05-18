import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int currentIndex = 0;
  String selectedFavoriteVibe = 'Sorpresa';

  static const List<String> favoriteVibes = [
    'Cita',
    'Amigos',
    'Solo',
    'Chill',
    'Fiesta',
    'Viaje',
    'Sorpresa',
  ];

  final List<_OnboardingSlide> slides = const [
    _OnboardingSlide(
      title: 'Planes perfectos para ahora',
      text:
          'Tonight encuentra ideas para cualquier momento: mañana, tarde o noche.',
    ),
    _OnboardingSlide(
      title: 'Elige tu vibe',
      text:
          'Cita, amigos, solo, chill, fiesta, sorpresa, viaje o grupo. Tú eliges el mood.',
    ),
    _OnboardingSlide(
      title: 'Descubre tu próximo plan',
      text: 'Usa tu ubicación para crear planes más cercanos y personalizados.',
    ),
    _OnboardingSlide(
      title: '¿Cuál es tu vibe favorita?',
      text:
          'La usaremos para darte un acceso rápido a planes que se sientan más tuyos.',
      isPreferenceStep: true,
    ),
  ];

  bool get isLastSlide => currentIndex == slides.length - 1;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF251329), Color(0xFF0D0B11), Color(0xFF08080C)],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final slide = slides[index];

                      if (slide.isPreferenceStep) {
                        return _FavoriteVibeSlide(
                          slide: slide,
                          vibes: favoriteVibes,
                          selectedVibe: selectedFavoriteVibe,
                          onSelected: (vibe) {
                            setState(() {
                              selectedFavoriteVibe = vibe;
                            });
                          },
                        );
                      }

                      return _SlideView(slide: slide);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressDots(count: slides.length, currentIndex: currentIndex),
                const SizedBox(height: 28),
                _OnboardingButton(
                  label: isLastSlide ? 'Empezar' : 'Siguiente',
                  onPressed: _handlePrimaryAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (!isLastSlide) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await OnboardingService.saveFavoriteVibe(selectedFavoriteVibe);
    await OnboardingService.markAsSeen();
    await const AnalyticsService().logOnboardingCompleted(
      favoriteVibe: selectedFavoriteVibe,
    );
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.text,
    this.isPreferenceStep = false,
  });

  final String title;
  final String text;
  final bool isPreferenceStep;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFE8B66B)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.24),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF100D10),
            size: 34,
          ),
        ),
        const SizedBox(height: 42),
        Text(
          slide.title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          slide.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FavoriteVibeSlide extends StatelessWidget {
  const _FavoriteVibeSlide({
    required this.slide,
    required this.vibes,
    required this.selectedVibe,
    required this.onSelected,
  });

  final _OnboardingSlide slide;
  final List<String> vibes;
  final String selectedVibe;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFE8B66B)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8B66B).withValues(alpha: 0.24),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFF100D10),
            size: 34,
          ),
        ),
        const SizedBox(height: 34),
        Text(
          slide.title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: vibes.map((vibe) {
            final isSelected = selectedVibe == vibe;

            return _FavoriteVibeChip(
              label: vibe,
              isSelected: isSelected,
              onTap: () => onSelected(vibe),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FavoriteVibeChip extends StatelessWidget {
  const _FavoriteVibeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? const Color(0xFFE8B66B)
          : Colors.white.withValues(alpha: 0.075),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE8B66B)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected ? const Color(0xFF100D10) : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = currentIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: isSelected ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8B66B)
                : Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFE8B66B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8B66B).withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            height: 62,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF100D10),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
