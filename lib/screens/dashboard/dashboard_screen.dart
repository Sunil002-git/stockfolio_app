import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/broker_selector_bar.dart';
import '../../widgets/stat_card.dart';
 
// Currency formatter — ₹12,450.75
final _inr = NumberFormat.currency(
  locale: 'en_IN', symbol: '₹', decimalDigits: 2,
);
String fmtInr(dynamic v) =>
  _inr.format((v as num?)?.toDouble() ?? 0.0);
 
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
 
class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool   _loading = true;
  String? _error;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  // Re-fetch whenever the broker selection changes.
  // didUpdateWidget is NOT called for provider changes.
  // Instead we use didChangeDependencies — it fires when
  // any dependency (like a watched provider) changes.
  int? _lastBrokerId = -99; // sentinel to detect first call
 
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
      final api      = context.read<ApiService>();
      final broker   = context.read<BrokerProvider>().brokerParam;
      final params   = broker != null ? {'broker': broker} : null;
      final response = await api.get('dashboard/', params: params);
      if (mounted) setState(() {
        _data    = response.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error   = 'Failed to load dashboard.';
        _loading = false;
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    // Watch BrokerProvider so subtitle updates when broker changes
    final bp          = context.watch<BrokerProvider>();
    final auth        = context.watch<AuthProvider>();
    final brokerLabel = bp.activeBrokerId != null
      ? '  —  ${bp.activeBrokerName}' : '';
 
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard$brokerLabel'),
        actions: [
          IconButton(
            icon:    const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () async {
              context.read<BrokerProvider>().clear();
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Broker selector bar (hidden if no brokers)
          const BrokerSelectorBar(),
          // Main content — scrollable
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
 
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline,
            color: AppColors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
            style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon:  const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      );
    }
    if (_data == null) return const SizedBox.shrink();
 
    final d = _data!;
    final balance  = (d['balance']          as num?)?.toDouble() ?? 0;
    final realPL   = (d['total_realized_pl'] as num?)?.toDouble() ?? 0;
    final invested = (d['total_invested']    as num?)?.toDouble() ?? 0;
    final charges  = (d['trade_charges']     as num?)?.toDouble() ?? 0;
    final deposit  = (d['total_deposit']     as num?)?.toDouble() ?? 0;
    final withdraw = (d['total_withdraw']    as num?)?.toDouble() ?? 0;
    final openPos  = d['open_positions']  as int? ?? 0;
    final closedPos= d['closed_positions'] as int? ?? 0;
    final totalPos = d['total_positions'] as int? ?? 0;
    final winRate  = (d['win_rate']       as num?)?.toDouble() ?? 0;
    final wins     = d['winning_trades']  as int? ?? 0;
    final losses   = d['losing_trades']   as int? ?? 0;
    final segments = d['segment_stats']   as Map<String, dynamic>? ?? {};
 
    return RefreshIndicator(
      onRefresh: _load, // pull down to reload
      color:     AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
 
          // ── Stat cards ─────────────────────────────────────
          // 2×2 grid using Row + Expanded
          Row(children: [
            Expanded(child: StatCard(
              label: 'Balance',
              value: fmtInr(balance),
              icon:  Icons.account_balance_wallet_outlined,
              color: balance >= 0 ? AppColors.brand : AppColors.red,
            )),
            const SizedBox(width: 10),
            Expanded(child: StatCard(
              label: 'Realized P&L',
              value: '${realPL >= 0 ? "+" : ""}${fmtInr(realPL)}',
              icon:  realPL >= 0
                ? Icons.trending_up : Icons.trending_down,
              color: realPL >= 0 ? AppColors.green : AppColors.red,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: StatCard(
              label: 'Invested',
              value: fmtInr(invested),
              icon:  Icons.pie_chart_outline,
              color: AppColors.orange,
            )),
            const SizedBox(width: 10),
            Expanded(child: StatCard(
              label: 'Charges Paid',
              value: fmtInr(charges),
              icon:  Icons.receipt_long_outlined,
              color: AppColors.textMuted,
            )),
          ]),
          const SizedBox(height: 20),
 
          // ── Balance breakdown ───────────────────────────────
          _SectionCard(
            title: 'Balance Breakdown',
            icon:  Icons.account_balance_outlined,
            child: Column(children: [
              _BreakdownRow(
                label: 'Total Deposits',
                value: '+${fmtInr(deposit)}',
                valueColor: AppColors.green,
                icon: Icons.arrow_downward,
                iconColor: AppColors.green,
              ),
              _BreakdownRow(
                label: 'Total Withdrawals',
                value: '−${fmtInr(withdraw)}',
                valueColor: AppColors.red,
                icon: Icons.arrow_upward,
                iconColor: AppColors.red,
              ),
              _BreakdownRow(
                label: 'Invested + Charges',
                value: '−${fmtInr(invested + charges)}',
                valueColor: AppColors.orange,
                icon: Icons.shopping_cart_outlined,
                iconColor: AppColors.orange,
              ),
              _BreakdownRow(
                label: 'Realized P&L',
                value: '${realPL >= 0 ? "+" : ""}${fmtInr(realPL)}',
                valueColor: realPL >= 0 ? AppColors.green : AppColors.red,
                icon: realPL >= 0
                  ? Icons.trending_up : Icons.trending_down,
                iconColor: realPL >= 0 ? AppColors.green : AppColors.red,
              ),
              const Divider(height: 24),
              _BreakdownRow(
                label: 'Available Balance',
                value: fmtInr(balance),
                valueColor: balance >= 0 ? AppColors.green : AppColors.red,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.brand,
                bold: true,
              ),
            ]),
          ),
          const SizedBox(height: 16),
 
          // ── Position stats ──────────────────────────────────
          _SectionCard(
            title: 'Positions',
            icon:  Icons.layers_outlined,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CountTile(
                  label: 'Total', value: totalPos,
                  color: AppColors.brand),
                _CountTile(
                  label: 'Open',  value: openPos,
                  color: AppColors.orange),
                _CountTile(
                  label: 'Closed',value: closedPos,
                  color: AppColors.textMuted),
                _CountTile(
                  label: 'Win %',
                  value: winRate,
                  isDouble: true,
                  suffix: '%',
                  color: winRate >= 50
                    ? AppColors.green : AppColors.red),
              ],
            ),
          ),
          const SizedBox(height: 16),
 
          // ── Segment breakdown ───────────────────────────────
          if (segments.isNotEmpty)
            _SectionCard(
              title: 'Segments',
              icon:  Icons.pie_chart_outline,
              child: Wrap(
                spacing: 10, runSpacing: 10,
                children: segments.entries
                  .where((e) =>
                    (e.value['count'] as int? ?? 0) > 0)
                  .map((e) => _SegmentTile(
                    key:   e.key,
                    data:  e.value as Map<String, dynamic>,
                  ))
                  .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
 
// ── Private helper widgets ───────────────────────────────────────
 
// Section card wrapper with title and icon
class _SectionCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Widget   child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.brand),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize:   15,
              color:      AppColors.textPrimary,
            )),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
 
// A single row in the balance breakdown
class _BreakdownRow extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    valueColor;
  final IconData icon;
  final Color    iconColor;
  final bool     bold;
  const _BreakdownRow({
    required this.label,   required this.value,
    required this.valueColor, required this.icon,
    required this.iconColor,  this.bold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? AppColors.textPrimary : AppColors.textMuted,
        ))),
        Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: valueColor,
        )),
      ]),
    );
  }
}
 
// Position count tile (Total, Open, Closed, Win%)
class _CountTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color   color;
  final bool    isDouble;
  final String  suffix;
  const _CountTile({
    required this.label,  required this.value,
    required this.color,  this.isDouble = false,
    this.suffix = '',
  });
  @override
  Widget build(BuildContext context) {
    final display = isDouble
      ? '${(value as double).toStringAsFixed(1)}$suffix'
      : '$value$suffix';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(display, style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textMuted)),
    ]);
  }
}
 
// Segment tile (Equity, Futures, CE, PE, MF)
class _SegmentTile extends StatelessWidget {
  final String             key;
  final Map<String,dynamic> data;
  const _SegmentTile({required String key, required this.data})
    : super(key: ValueKey(key));
  @override
  Widget build(BuildContext context) {
    final label  = data['label']       as String? ?? '?';
    final count  = data['count']        as int?    ?? 0;
    final pl     = (data['profit_loss'] as num?)?.toDouble() ?? 0;
    final isProfit = pl >= 0;
    return Container(
      width:   140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('$count positions', style: const TextStyle(
            fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            '${isProfit ? "+" : ""}${fmtInr(pl)}',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold,
              color: isProfit ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
