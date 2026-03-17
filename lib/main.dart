import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_state_notifier.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  final authNotifier = AuthStateNotifier();
  final router = AppRouter.createRouter(authNotifier);

  runApp(MyApp(router: router, authNotifier: authNotifier));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router, required this.authNotifier});

  final GoRouter router;
  final AuthStateNotifier authNotifier;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: BlocProvider(
        create: (context) => AuthBloc(),
        child: BlocListener<AuthBloc, AppAuthState>(
          listener: (context, state) {
            authNotifier.isAuthenticated = state is AuthAuthenticated;
          },
          child: MaterialApp.router(
            title: 'Kooba Stock Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      ),
    );
  }
}
