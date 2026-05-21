import 'package:flutter/material.dart';

Route<T> tonightPageRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.035, 0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}
