import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

/// Single source of truth for the shell's bottom navigation visibility.
///
/// Both the Home and Categories tabs drive the same controller, so switching
/// tabs always restores the bar and each tab's scroll tracking stays in sync
/// with what is actually on screen.
class BottomBarVisibilityController extends ChangeNotifier {
  bool _visible = true;

  bool get visible => _visible;

  void show() => _setVisible(true);

  void hide() => _setVisible(false);

  void _setVisible(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
  }
}

/// Hides the shell's bottom navigation while the user scrolls down and brings
/// it back when the scroll stops, the list reaches the top, or the user
/// scrolls up again.
///
/// The child keeps its own scroll behaviour; this widget only observes
/// notifications that bubble up from the nearest vertical scrollable.
class BottomBarAutoHide extends StatefulWidget {
  const BottomBarAutoHide({
    super.key,
    required this.controller,
    required this.child,
    this.hideDelta = 6,
    this.restoreDelay = const Duration(milliseconds: 500),
  });

  /// When null the wrapper is inert, which keeps standalone screens and tests
  /// simple.
  final BottomBarVisibilityController? controller;
  final Widget child;
  final double hideDelta;
  final Duration restoreDelay;

  @override
  State<BottomBarAutoHide> createState() => _BottomBarAutoHideState();
}

class _BottomBarAutoHideState extends State<BottomBarAutoHide> {
  Timer? _restoreTimer;
  double _lastOffset = 0;

  @override
  void dispose() {
    _restoreTimer?.cancel();
    super.dispose();
  }

  void _cancelRestore() => _restoreTimer?.cancel();

  bool _onNotification(ScrollNotification notification) {
    final controller = widget.controller;
    if (controller == null ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _cancelRestore();
      _lastOffset = notification.metrics.pixels;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      final delta = offset - _lastOffset;
      _lastOffset = offset;

      if (offset <= 0 || delta < -widget.hideDelta) {
        _cancelRestore();
        controller.show();
      } else if (delta > widget.hideDelta) {
        _cancelRestore();
        controller.hide();
      }
      return false;
    }

    final stopped =
        notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle);
    if (!stopped) {
      return false;
    }

    _cancelRestore();
    _restoreTimer = Timer(widget.restoreDelay, () {
      if (mounted) {
        controller.show();
      }
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
