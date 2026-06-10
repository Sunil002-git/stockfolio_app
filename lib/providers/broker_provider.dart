import 'package:flutter/material.dart';

class Broker {
  final int id;
  final String name;
  final String? accountId;
  final bool isActive;
  final int tradeCount;

  const Broker({
    required this.id,
    required this.name,
    this.accountId,
    required this.isActive,
    required this.tradeCount,
  });

  factory Broker.fromJson(Map<String, dynamic> j) => Broker(
    id: j['id'] as int,
    name: j['name'] as String,
    accountId: j['account_id'] as String?,
    isActive: j['is_active'] as bool,
    tradeCount: j['trade_count'] as int,
  );
}

// BrokerProvider — equivalent to BrokerContext.js
// Holds the brokers list and which broker is currently selected.
//
// activeBrokerId == null  →  "All Brokers" (no filter)
// activeBrokerId == 3     →  only show data for broker with id 3
class BrokerProvider extends ChangeNotifier {
  List<Broker> _brokers = [];
  int? _activeBrokerId; // null = All Brokers

  List<Broker> get brokers => _brokers;
  int? get activeBrokerId => _activeBrokerId;

  // brokerParam — the string to append as ?broker= in API calls.
  // null means no filter (all brokers).
  // Equivalent to brokerParam in BrokerContext.js.
  String? get brokerParam =>
      _activeBrokerId != null ? _activeBrokerId.toString() : null;
  // The display name for the currently selected broker.
  // Used in screen subtitles: "Dashboard — Zerodha"
  String get activeBrokerName {
    if (_activeBrokerId == null) return 'All Brokers';
    try {
      return _brokers.firstWhere((b) => b.id == _activeBrokerId).name;
    } catch (_) {
      return 'All Brokers';
    }
  }

  // Called after login — loads brokers from API.
  // Pass the ApiService instance.
  Future<void> loadBrokers(dynamic api) async {
    try {
      final res = await api.get('brokers/');
      final list = res.data as List<dynamic>;
      _brokers = list
          .map((j) => Broker.fromJson(j as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Silently faul - broker filter just won't show
    }
  }

  // Called when user taps a broker pill
  void setActiveBroker(int? id) {
    _activeBrokerId = id;
    notifyListeners(); // triggers rebuild on all watching screens
  }

  //   Reset when user logs out.
  void clear() {
    _brokers = [];
    _activeBrokerId = null;
    notifyListeners();
  }
}
