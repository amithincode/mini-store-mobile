import 'package:flutter/material.dart';

/// Horizontal slide shared by every pushed page.
///
/// The incoming page travels in from the right while the page underneath
/// shifts slightly left and dims. The overlap between the two pages hides the
/// gap a pure full-width slide would leave and reads as depth rather than a
/// flat swap. Popping a route plays the same motion in reverse.
class SideSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SideSlidePageTransitionsBuilder();

  static final Animatable<Offset> _incoming = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final Animatable<Offset> _outgoing = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.25, 0),
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final Animatable<double> _outgoingOpacity = Tween<double>(
    begin: 1,
    end: 0.92,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Respect the platform accessibility setting instead of forcing motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return SlideTransition(
      position: _outgoing.animate(secondaryAnimation),
      child: FadeTransition(
        opacity: _outgoingOpacity.animate(secondaryAnimation),
        child: SlideTransition(
          position: _incoming.animate(animation),
          child: child,
        ),
      ),
    );
  }
}
