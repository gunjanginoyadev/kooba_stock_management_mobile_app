import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/auth/auth_state_notifier.dart';
import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use bundled fonts under google_fonts/ — do not hit fonts.gstatic.com
  // (fails offline / when DNS cannot resolve the host).
  GoogleFonts.config.allowRuntimeFetching = false;

  if (FirebaseConfig.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
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
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => child!,
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
