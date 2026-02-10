class AppConstants {
  // App Info
  static const String appName = 'Kooba';
  static const String appTagline = 'Stock Management';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';

  // Stock / app routes
  static const String stockHubRoute = '/stock-hub';
  static const String addStockRoute = '/add-stock';
  static const String stockSuccessRoute = '/stock-success';
  static const String manageItemsRoute = '/manage-items';

  // Item & report routes (static UI only for now)
  static const String itemDetailsRoute = '/item-details';
  static const String entryDetailsRoute = '/entry-details';
  static const String editEntryRoute = '/edit-entry';

  static const String reportsHomeRoute = '/reports';
  static const String reportFiltersRoute = '/report-filters';
  static const String stockReportRoute = '/stock-report';
  static const String pdfPreviewRoute = '/pdf-preview';

  static const String profileRoute = '/profile';

  static const String emailVerificationRoute = '/email-verification';
  static const String addItemCategoryRoute = '/add-item-category';
  static const String stockUsageRoute = '/stock-usage';
  static const String stockHistoryRoute = '/stock-history';
  
  // Stock Constants
  static const int lowStockThreshold = 10;
}

