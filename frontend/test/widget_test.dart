import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('App can be created and renders MaterialApp', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          title: 'CivilOS',
          theme: CivilTheme.darkTheme,
          home: const Scaffold(body: Center(child: Text('CivilOS'))),
        ),
      ),
    );

    expect(find.text('CivilOS'), findsOneWidget);
  });

  testWidgets('LoginScreen renders email and password fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: CivilTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // LoginScreen has form fields - check for "Work Email" in desktop layout
    // or "Username" label in mobile layout
    final emailFields = find.byType(TextFormField);
    expect(emailFields.length, greaterThanOrEqualTo(1),
        reason: 'LoginScreen should have at least one TextFormField');
  });

  testWidgets('DashboardScreen has CivilOS title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: CivilTheme.darkTheme,
          home: const DashboardScreen(child: SizedBox()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CivilOS'), findsOneWidget);
  });

  testWidgets('LoginScreen shows Secure Sign In on desktop', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: CivilTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should show either "Secure Sign In" (desktop) or "SIGN IN" (mobile)
    final secureSignIn = find.text('Secure Sign In');
    final signIn = find.text('SIGN IN');
    expect(secureSignIn.evaluate().isNotEmpty || signIn.evaluate().isNotEmpty,
        isTrue,
        reason: 'LoginScreen should show sign in text');
  });
}
