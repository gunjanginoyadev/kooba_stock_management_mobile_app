import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
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
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
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
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Stock / home area
      GoRoute(
        path: AppConstants.stockHubRoute,
        name: 'stock-hub',
        builder: (context, state) => const StockHubScreen(),
      ),
      GoRoute(
        path: AppConstants.addStockRoute,
        name: 'add-stock',
        builder: (context, state) => const AddStockScreen(),
      ),
      GoRoute(
        path: AppConstants.stockSuccessRoute,
        name: 'stock-success',
        builder: (context, state) => const StockSuccessScreen(),
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
        path: AppConstants.reportsHomeRoute,
        name: 'reports-home',
        builder: (context, state) => const ReportsHomeScreen(),
      ),
      GoRoute(
        path: AppConstants.reportFiltersRoute,
        name: 'report-filters',
        builder: (context, state) => const ReportFiltersScreen(),
      ),
      GoRoute(
        path: AppConstants.stockReportRoute,
        name: 'stock-report',
        builder: (context, state) => const StockReportScreen(),
      ),
      GoRoute(
        path: AppConstants.pdfPreviewRoute,
        name: 'pdf-preview',
        builder: (context, state) => const PdfPreviewScreen(),
      ),

      // Profile
      GoRoute(
        path: AppConstants.profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

