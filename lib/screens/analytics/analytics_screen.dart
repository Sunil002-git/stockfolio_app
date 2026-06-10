import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/broker_selector_bar.dart';
 
final _inr = NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:0);
 
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}
 
class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'year';
  Map<String,dynamic>? _data;
  bool _loading = true;
  int? _lastBroker = -99;
 
  static const _periods = [
    ['Week',   'week'],
    ['Month',  'month'],
    ['Year',   'year'],
    ['All',    'all'],
  ];
 
  @override
  void initState() { super.initState(); _load(); }
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = context.read<BrokerProvider>().activeBrokerId;
    if (b != _lastBroker) { _lastBroker = b; _load(); }
  }
 
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api    = context.read<ApiService>();
      final broker = context.read<BrokerProvider>().brokerParam;
      final params = <String,String>{'period': _period};
      if (broker != null) params['broker'] = broker;
      final res = await api.get('analytics/', params: params);
      if (mounted) setState(() {
        _data    = res.data as Map<String,dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'),
      actions: [
  IconButton(
    icon: const Icon(Icons.auto_graph),
    tooltip: 'Predict',
    onPressed: () => context.push('/predict'),
  ),
],

      ),
      body: Column(
        children: [
          const BrokerSelectorBar(),
          // Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
            child: Row(
              children: _periods.map((p) => Padding(
                padding: const EdgeInsets.only(right:8),
                child: FilterChip(
                  label:    Text(p[0]),
                  selected: _period == p[1],
                  onSelected: (_) => setState(() { _period=p[1]; _load(); }),
                  selectedColor:   AppColors.brand.withOpacity(0.2),
                  checkmarkColor:  AppColors.brand,
                  backgroundColor: AppColors.bgInput,
                  side: BorderSide(color: _period==p[1]
                    ? AppColors.brand : AppColors.border),
                  labelStyle: TextStyle(color: _period==p[1]
                    ? AppColors.brand : AppColors.textMuted),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _data == null
                ? const Center(child: Text("No data",
                    style: TextStyle(color: AppColors.textMuted)))
                : RefreshIndicator(
                    onRefresh: _load, color: AppColors.brand,
                    child: _buildContent(),
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildContent() {
    final d          = _data!;
    final monthlyPl  = d['monthly_pl']     as List<dynamic>? ?? [];
    final totalPl    = (d['total_pl']       as num?)?.toDouble() ?? 0;
    final winRate    = (d['win_rate']        as num?)?.toDouble() ?? 0;
    final totalTrades= d['total_trades']    as int? ?? 0;
    final topSymbols = d['top_symbols']     as List<dynamic>? ?? [];
 
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
 
        // ── Summary row ──────────────────────────────────────
        Row(children: [
          _StatTile(
            label: 'Total P&L',
            value: (totalPl >= 0 ? '+' : '') + _inr.format(totalPl),
            color: totalPl >= 0 ? AppColors.green : AppColors.red,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Win Rate',
            value: '${winRate.toStringAsFixed(1)}%',
            color: winRate >= 50 ? AppColors.green : AppColors.red,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Trades',
            value: '$totalTrades',
            color: AppColors.brand,
          ),
        ]),
        const SizedBox(height: 20),
 
        // ── Monthly P&L bar chart ─────────────────────────────
        if (monthlyPl.isNotEmpty) ...[
          _SectionHeader(title: 'Monthly P&L', icon: Icons.bar_chart),
          const SizedBox(height: 12),
          _PLBarChart(monthlyData: monthlyPl),
          const SizedBox(height: 20),
        ],
 
        // ── Top symbols ───────────────────────────────────────
        if (topSymbols.isNotEmpty) ...[
          _SectionHeader(title: 'Top Symbols', icon: Icons.emoji_events_outlined),
          const SizedBox(height: 12),
          ...topSymbols.take(8).map((s) {
            final sym = s as Map<String,dynamic>;
            final pl  = (sym['total_pl'] as num).toDouble();
            return _SymbolRow(symbol: sym, pl: pl);
          }),
        ],
      ],
    );
  }
}
 
// ── P&L Bar Chart ────────────────────────────────────────────────
class _PLBarChart extends StatelessWidget {
  final List<dynamic> monthlyData;
  const _PLBarChart({required this.monthlyData});
 
  @override
  Widget build(BuildContext context) {
    // Build BarChartGroupData from the API response
    // Each item: {"month": "Jan", "pl": 3200.0}
    final groups = monthlyData.asMap().entries.map((e) {
      final item = e.value as Map<String,dynamic>;
      final pl   = (item['pl'] as num).toDouble();
      final isProfit = pl >= 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            fromY: pl < 0 ? pl : 0,
            toY:   pl < 0 ? 0  : pl,
            color: isProfit ? AppColors.green : AppColors.red,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
 
    // Find the max absolute value for the chart Y axis
    final maxY = monthlyData.fold<double>(0, (m, item) {
      final pl = (item as Map<String,dynamic>)['pl'] as num;
      return pl.abs() > m ? pl.abs().toDouble() : m;
    });
 
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY:  maxY * 1.15,
          minY:  -(maxY * 1.15),
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:  AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 56,
                getTitlesWidget: (v, _) => Text(
                  v == 0 ? '0' : (v >= 1000
                    ? '${(v/1000).toStringAsFixed(0)}k'
                    : v.toStringAsFixed(0)),
                  style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= monthlyData.length) {
                    return const Text('');
                  }
                  final item = monthlyData[i] as Map<String,dynamic>;
                  return Text(item['month'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted));
                },
              ),
            ),
          ),
          // Tooltip on tap
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final item = monthlyData[group.x] as Map<String,dynamic>;
                final pl   = (item['pl'] as num).toDouble();
                return BarTooltipItem(
                  '${item['month']}: ${pl >= 0 ? '+' : ''}${NumberFormat.compactCurrency(symbol: '₹').format(pl)}',
                  TextStyle(
                    color: pl >= 0 ? AppColors.green : AppColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
 
// ── Helper widgets ───────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value; final Color color;
  const _StatTile({required this.label,required this.value,required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold,
          fontSize: 15, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(
          fontSize: 10, color: AppColors.textMuted)),
      ]),
    ));
  }
}
 
class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.brand),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold,
        fontSize: 16, color: AppColors.textPrimary)),
    ]);
  }
}
 
class _SymbolRow extends StatelessWidget {
  final Map<String,dynamic> symbol; final double pl;
  const _SymbolRow({required this.symbol, required this.pl});
  @override
  Widget build(BuildContext context) {
    final sym    = symbol['symbol'] as String;
    final trades = symbol['trades_count'] as int? ?? 0;
    final isProfit = pl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Text(sym, style: const TextStyle(fontWeight: FontWeight.bold,
          fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Text('$trades trades', style: const TextStyle(
          fontSize: 11, color: AppColors.textMuted)),
        const Spacer(),
        Text('${isProfit ? '+' : ''}${_inr.format(pl)}',
          style: TextStyle(fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isProfit ? AppColors.green : AppColors.red)),
      ]),
    );
  }
}
