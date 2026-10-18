import 'package:flutter/material.dart';

/// Screens at or above this width use the wide layouts.
const double wideBreakpoint = 840;

/// Keeps the content of a screen at a comfortable reading width on wide
/// windows (tablets, Windows): it is centred and at most [maxWidth] wide.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, this.maxWidth = 720, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
