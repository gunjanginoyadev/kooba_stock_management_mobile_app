import 'package:flutter/foundation.dart';

/// Broadcasts when stock data changes so screens like Home can reload.
class StockRefreshNotifier extends ChangeNotifier {
  StockRefreshNotifier._();
  static final StockRefreshNotifier instance = StockRefreshNotifier._();

  void notifyStockChanged() => notifyListeners();
}
