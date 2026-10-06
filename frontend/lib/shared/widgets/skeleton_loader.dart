import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: CivilTheme.surface,
      end: CivilTheme.border,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.count = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return SkeletonLoader(height: itemHeight);
      },
    );
  }
}
