import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/broker_provider.dart';
import '../../widgets/broker_selector_bar.dart';
 
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
 
class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});
  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}
 
class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  List<dynamic> _history  = [];
  bool          _loading  = true;
  int?          _lastBroker = -99;
  final _symbolCtrl = TextEditingController();
  String  _tradeType = '';  // '' | 'buy' | 'sell'
 
  @override
  void initState() { super.initState(); _load(); }
 
  @override
  void dispose() { _symbolCtrl.dispose(); super.dispose(); }
 
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
      final params = <String,String>{};
      final sym    = _symbolCtrl.text.trim().toUpperCase();
      if (sym.isNotEmpty)          params['symbol']     = sym;
      if (_tradeType.isNotEmpty)   params['trade_type'] = _tradeType;
      if (broker != null)          params['broker']     = broker;
      final res = await api.get('trades/history/', params: params);
      final data = res.data as Map<String,dynamic>;
      if (mounted) setState(() {
        _history = data['history'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade History'),
      ),
      body: Column(
        children: [
          const BrokerSelectorBar(),
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16,10,16,6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _symbolCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText:    'Symbol filter...',
                    prefixIcon:  const Icon(Icons.search),
                    suffixIcon: _symbolCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _symbolCtrl.clear(); _load();
                          },
                        )
                      : null,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 10),
              ...[['All',''],['Buy','buy'],['Sell','sell']].map((item) =>
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label:    Text(item[0]),
                    selected: _tradeType == item[1],
                    onSelected: (_) => setState(() {
                      _tradeType = item[1]; _load();
                    }),
                    selectedColor: AppColors.brand.withOpacity(0.2),
                    checkmarkColor: AppColors.brand,
                    backgroundColor: AppColors.bgInput,
                    side: BorderSide(color: _tradeType == item[1]
                      ? AppColors.brand : AppColors.border),
                    labelStyle: TextStyle(color: _tradeType == item[1]
                      ? AppColors.brand : AppColors.textMuted),
                  ),
                )
              ).toList(),
            ]),
          ),
          // List
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                ? const Center(child: Text('No trades found.',
                    style: TextStyle(color: AppColors.textMuted)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.brand,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16,4,16,16),
                      itemCount: _history.length,
                      itemBuilder: (_, i) =>
                        _TradeFeedItem(item: _history[i] as Map<String,dynamic>),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
 
// Single trade feed item
class _TradeFeedItem extends StatelessWidget {
  final Map<String,dynamic> item;
  const _TradeFeedItem({required this.item});
 
  @override
  Widget build(BuildContext context) {
    final isBuy    = item['trade_type'] == 'buy';
    final symbol   = item['symbol']     as String;
    final price    = (item['price']     as num).toDouble();
    final qty      = item['quantity']   as int;
    final date     = item['date']       as String;
    final pl       = (item['profit_loss'] as num?)?.toDouble();
    final broker   = item['broker_name'] as String?;
    final color    = isBuy ? AppColors.brand : AppColors.red;
 
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Buy/Sell badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(isBuy ? '▲ BUY' : '▼ SELL',
                  style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 11, color: color)),
              ),
              const SizedBox(width: 8),
              Text(symbol,
                style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16, color: AppColors.textPrimary)),
              // Broker tag
              if (broker != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                  ),
                  child: Text(broker,
                    style: const TextStyle(fontSize: 10,
                      color: AppColors.purple, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Text(date,
                style: const TextStyle(fontSize: 12,
                  color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_inr.format(price)}  ×  $qty',
                style: const TextStyle(fontSize: 13,
                  color: AppColors.textMuted)),
              const Spacer(),
              if (pl != null)
                Text('${pl >= 0 ? "+" : ""}${_inr.format(pl)}',
                  style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: pl >= 0 ? AppColors.green : AppColors.red)),
            ]),
          ],
        ),
      ),
    );
  }
}
