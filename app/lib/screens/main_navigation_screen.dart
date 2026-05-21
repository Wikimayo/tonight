import 'package:flutter/material.dart';

import '../core/constants/app_texts.dart';
import '../services/haptic_service.dart';
import '../services/language_service.dart';
import 'chat_plan_screen.dart';
import 'community_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'saved_plans_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  late final List<Widget> tabs = const [
    HomeScreen(),
    ChatPlanScreen(),
    ExploreScreen(),
    CommunityScreen(),
    SavedPlansScreen(showBackButton: false),
    SettingsScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, language, child) {
        final texts = AppTexts.of(language);

        return Scaffold(
          extendBody: false,
          body: Stack(
            children: tabs.indexed.map((entry) {
              final index = entry.$1;
              final tab = entry.$2;
              final isSelected = selectedIndex == index;

              return Offstage(
                offstage: !isSelected,
                child: TickerMode(
                  enabled: isSelected,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    opacity: isSelected ? 1 : 0,
                    child: tab,
                  ),
                ),
              );
            }).toList(),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121018).withValues(alpha: 0.96),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.36),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const minimumNavWidth = 460.0;
                    final isCompact = constraints.maxWidth < minimumNavWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: isCompact
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: isCompact
                            ? minimumNavWidth
                            : constraints.maxWidth,
                        child: BottomNavigationBar(
                          currentIndex: selectedIndex,
                          onTap: (index) {
                            if (index != selectedIndex) {
                              HapticService.selectionClick();
                            }
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          type: BottomNavigationBarType.fixed,
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          selectedItemColor: const Color(0xFFE8B66B),
                          unselectedItemColor: Colors.white.withValues(
                            alpha: 0.48,
                          ),
                          selectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                          items: [
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.home_rounded),
                              label: texts.home,
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.chat_bubble_rounded),
                              label: texts.chat,
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.travel_explore_rounded),
                              label: texts.explore,
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.forum_rounded),
                              label: texts.community,
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.bookmarks_rounded),
                              label: texts.saved,
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.settings_rounded),
                              label: texts.settings,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
