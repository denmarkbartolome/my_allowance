import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/budget_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const MyAllowanceApp());
}

class MyAllowanceApp extends StatelessWidget {
  const MyAllowanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<SupabaseService>(
      create: (_) => SupabaseService(),
      child: MaterialApp(
        title: 'MyAllowance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

/// Shows the login screen or the app, depending on the Supabase session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    return StreamBuilder<AuthState>(
      stream: service.authChanges,
      builder: (context, _) {
        final session = service.currentSession;
        if (session == null) return const AuthScreen();

        // Keyed by user id so a different account always starts fresh.
        return ChangeNotifierProvider<BudgetController>(
          key: ValueKey(session.user.id),
          create: (ctx) => BudgetController(ctx.read<SupabaseService>())..load(),
          child: const HomeShell(),
        );
      },
    );
  }
}
