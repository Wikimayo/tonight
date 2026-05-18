import 'package:flutter/material.dart';

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
    ExploreScreen(),
    SavedPlansScreen(showBackButton: false),
    SettingsScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFFE8B66B),
              unselectedItemColor: Colors.white.withValues(alpha: 0.48),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.travel_explore_rounded),
                  label: 'Explorar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmarks_rounded),
                  label: 'Guardados',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
