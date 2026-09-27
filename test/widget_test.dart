// Smoke test for MyAllowance.
//
// The default flutter_test template checks for a counter app, which this
// project doesn't have, so that test always failed here. This one instead
// renders the actual login screen and checks it comes up correctly,
// without needing a live Supabase connection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:my_allowance/core/theme.dart';
import 'package:my_allowance/screens/auth_screen.dart';
import 'package:my_allowance/services/supabase_service.dart';

void main() {
  testWidgets('Auth screen shows the MyAllowance login form', (tester) async {
    await tester.pumpWidget(
      Provider<SupabaseService>(
        create: (_) => SupabaseService(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('MyAllowance'), findsOneWidget);
    expect(find.text('Log in'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2)); // email + password

    // Switching to sign up reveals the name field.
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3)); // name, email, password
  });
}
