import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../models/trade_group.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/broker_selector_bar.dart';
import 'position_card.dart';
import 'sell_trade_sheet.dart';
import '../trades/add_trade_screen.dart';
 
class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});
  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}
 
class _PositionsScreenState extends State<PositionsScreen>
    with SingleTickerProviderStateMixin {
 
  // TabController for Open / Closed tabs
  late TabController _tabController;
  List<TradeGroup> _positions    = [];
  bool             _loading      = true;
  String?          _error;
  String           _segFilter    = '';  // '' = all segments
  int?             _lastBrokerId = -99;
 
  static const _segments = [
    {'key': '',        'label': 'All'},
    {'key': 'equity',  'label': 'Equity'},
    {'key': 'futures', 'label': 'Futures'},
    {'key': 'ce',      'label': 'CE'},
    {'key': 'pe',      'label': 'PE'},
    {'key': 'mf',      'label': 'MF'},
  ];
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Reload when tab changes (Open ↔ Closed)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = context.read<BrokerProvider>().activeBrokerId;
    if (current != _lastBrokerId) {
      _lastBrokerId = current;
      _load();
    }
  }
 
  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api    = context.read<ApiService>();
      final broker = context.read<BrokerProvider>().brokerParam;
      // Tab 0 = open (is_closed=false), Tab 1 = closed (is_closed=true)
      final isClosed = _tabController.index == 1 ? 'true' : 'false';
      final params = <String, String>{'is_closed': isClosed};
      if (broker != null)       params['broker']  = broker;
      if (_segFilter.isNotEmpty) params['segment'] = _segFilter;
      final res = await api.get(
        'positions/', params: params);
      final list = res.data as List<dynamic>;
      if (mounted) setState(() {
        _positions = list.map((j) =>
          TradeGroup.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Failed to load positions.';
        _loading = false;
      });
    }
  }
 
  // Opens the sell bottom sheet for a position
  void _openSell(TradeGroup position) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,  // allows full-height sheet
      backgroundColor: Colors.transparent,
      builder: (_) => SellTradeSheet(position: position),
    ).then((sold) {
      // sold == true means a sell was submitted — reload
      if (sold == true) _load();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand,
          labelColor:     AppColors.brand,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      // FAB — opens Add Trade screen
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddTradeScreen(),
            ),
          );
          if (added == true) _load();
        },
        backgroundColor: AppColors.brand,
        icon:  const Icon(Icons.add, color: Colors.white),
        label: const Text('Buy Trade',
          style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const BrokerSelectorBar(),
          _buildSegmentFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }
 
  // Horizontal segment filter chip row
  Widget _buildSegmentFilter() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _segments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final key   = _segments[i]['key']!;
          final label = _segments[i]['label']!;
          final active = _segFilter == key;
          return FilterChip(
            label: Text(label),
            selected: active,
            onSelected: (_) {
              setState(() => _segFilter = key);
              _load();
            },
            selectedColor:    AppColors.brand.withOpacity(0.18),
            checkmarkColor:   AppColors.brand,
            labelStyle: TextStyle(
              color: active ? AppColors.brand : AppColors.textMuted,
              fontWeight: active
                ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: active
                ? AppColors.brand
                : AppColors.border,
            ),
            backgroundColor: AppColors.bgCard,
            showCheckmark: false,
          );
        },
      ),
    );
  }
 
  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
            color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
            style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ));
    }
    if (_positions.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined,
            size: 64,
            color: AppColors.brand.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _tabController.index == 0
              ? 'No open positions'
              : 'No closed positions',
            style: const TextStyle(
              fontSize: 18, color: AppColors.textMuted),
          ),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _positions.length,
        itemBuilder: (_, i) => PositionCard(
          position:  _positions[i],
          // Only show sell button on open positions
          onSell: _tabController.index == 0
            ? () => _openSell(_positions[i])
            : null,
        ),
      ),
    );
  }
}
