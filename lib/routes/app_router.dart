import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state_notifier.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/items/screens/add_item_category_screen.dart';
import '../../features/items/screens/edit_stock_entry_screen.dart';
import '../../features/items/screens/entry_details_screen.dart';
import '../../features/items/screens/item_details_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/pdf_preview_screen.dart';
import '../../features/reports/screens/report_filters_screen.dart';
import '../../features/reports/screens/reports_home_screen.dart';
import '../../features/reports/screens/stock_report_screen.dart';
import '../../features/stock/screens/add_stock_screen.dart';
import '../../features/stock/screens/manage_items_screen.dart';
import '../../features/stock/screens/stock_history_screen.dart';
import '../../features/stock/screens/stock_hub_screen.dart';
import '../../features/stock/screens/stock_success_screen.dart';
import '../../features/stock/screens/stock_usage_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthStateNotifier authNotifier) {
    return GoRouter(
      initialLocation: AppConstants.splashRoute,
      refreshListenable: authNotifier,
      redirect: (BuildContext context, GoRouterState state) {
        final location = state.matchedLocation;
        final isAuth = authNotifier.isAuthenticated;

        if (isAuth == null) return null;

        final isPublicRoute = location == AppConstants.splashRoute ||
            location == AppConstants.loginRoute ||
            location == AppConstants.registerRoute ||
            location == AppConstants.forgotPasswordRoute ||
            location == AppConstants.emailVerificationRoute;

        if (!isAuth && !isPublicRoute) return AppConstants.loginRoute;
        if (isAuth && (location == AppConstants.loginRoute ||
            location == AppConstants.registerRoute ||
            location == AppConstants.forgotPasswordRoute)) {
          return AppConstants.homeRoute;
        }
        return null;
      },
      routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.emailVerificationRoute,
        name: 'email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      // Main app shell: bottom nav with 4 tabs (state preserved when switching)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: navigationShell,
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.homeRoute,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.stockHubRoute,
                name: 'stock-hub',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StockHubScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.reportsHomeRoute,
                name: 'reports-home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReportsHomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.profileRoute,
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Stock / home area (detail screens, full screen)
      GoRoute(
        path: AppConstants.addStockRoute,
        name: 'add-stock',
        builder: (context, state) => const AddStockScreen(),
      ),
      GoRoute(
        path: AppConstants.stockSuccessRoute,
        name: 'stock-success',
        builder: (context, state) => StockSuccessScreen(
          extra: state.extra is Map<String, dynamic>
              ? state.extra! as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: AppConstants.manageItemsRoute,
        name: 'manage-items',
        builder: (context, state) => const ManageItemsScreen(),
      ),
      GoRoute(
        path: AppConstants.stockUsageRoute,
        name: 'stock-usage',
        builder: (context, state) => const StockUsageScreen(),
      ),
      GoRoute(
        path: AppConstants.stockHistoryRoute,
        name: 'stock-history',
        builder: (context, state) => const StockHistoryScreen(),
      ),

      // Item detail / entry detail
      GoRoute(
        path: AppConstants.itemDetailsRoute,
        name: 'item-details',
        builder: (context, state) => const ItemDetailsScreen(),
      ),
      GoRoute(
        path: AppConstants.entryDetailsRoute,
        name: 'entry-details',
        builder: (context, state) => const EntryDetailsScreen(),
      ),
      GoRoute(
        path: AppConstants.editEntryRoute,
        name: 'edit-entry',
        builder: (context, state) => const EditStockEntryScreen(),
      ),
      GoRoute(
        path: AppConstants.addItemCategoryRoute,
        name: 'add-item-category',
        builder: (context, state) => const AddItemCategoryScreen(),
      ),

      // Reports
      GoRoute(
        path: AppConstants.reportFiltersRoute,
        name: 'report-filters',
        builder: (context, state) => const ReportFiltersScreen(),
      ),
      GoRoute(
        path: AppConstants.stockReportRoute,
        name: 'stock-report',
        builder: (context, state) => StockReportScreen(
          reportType: state.extra is Map ? (state.extra as Map)['type'] as String? : null,
        ),
      ),
      GoRoute(
        path: AppConstants.pdfPreviewRoute,
        name: 'pdf-preview',
        builder: (context, state) => const PdfPreviewScreen(),
      ),

    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
    );
  }
}

