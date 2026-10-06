import 'package:flutter/material.dart';
import 'theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CivilTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CivilTheme.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: CivilTheme.primary,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!, style: const TextStyle(color: CivilTheme.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CivilTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CivilTheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CivilTheme.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity * 0.6,
                      decoration: BoxDecoration(
                        color: CivilTheme.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: double.infinity * 0.4,
                      decoration: BoxDecoration(
                        color: CivilTheme.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
