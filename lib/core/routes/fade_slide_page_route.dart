import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_motion.dart';

/// A softer alternative to the platform's default push transition — fades
/// in while sliding up slightly, instead of the abrupt full-screen slide.
/// Used for in-feature navigation (opening a screenshot, opening a folder)
/// so moving around the app feels calmer.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.standard,
            // Ease-out on the way back too — but *flipped*, which is the part
            // this used to get wrong. Passing the forward curve straight
            // through looks right and behaves like an ease-in, because in
            // reverse it is sampled at a value counting down from 1 where a
            // strong ease-out is nearly flat. See AppMotion.standardReverse.
            reverseCurve: AppMotion.standardReverse,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
