import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CivilScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const CivilScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivilTheme.background,
      floatingActionButton: floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 900),
                  child: Column(
                    children: [
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              if (Navigator.canPop(context))
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: CivilTheme.textSecondary),
                                  onPressed: () => Navigator.pop(context),
                                )
                              else
                                const IconButton(
                                  icon: Icon(Icons.menu, color: CivilTheme.textSecondary),
                                  onPressed: null,
                                ),
                              const Spacer(),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: CivilTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (actions != null) ...actions!,
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
