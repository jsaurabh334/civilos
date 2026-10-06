import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.baseColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: baseColor.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
