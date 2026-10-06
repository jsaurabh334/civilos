import 'package:flutter/material.dart';

class RefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF06B6D4),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
