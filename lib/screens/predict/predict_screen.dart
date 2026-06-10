import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/auth_text_field.dart';
 
final _inr = NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:2);
 
class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}
 
class _PredictScreenState extends State<PredictScreen> {
  final _tickerCtrl = TextEditingController();
  int    _days       = 30;
  Map<String,dynamic>? _result;
  bool   _loading    = false;
  String? _error;
 
  static const _dayOptions = [7, 14, 30, 60, 90];
 
  @override
  void dispose() { _tickerCtrl.dispose(); super.dispose(); }
 
  Future<void> _predict() async {
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) {
      setState(() => _error = 'Enter a stock ticker (e.g. RELIANCE.NS)');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final res = await context.read<ApiService>().post('predict/', data: {
        'ticker':       ticker,
        'forecast_days': _days,
      });
      if (mounted) setState(() {
        _result  = res.data as Map<String,dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      if (mounted) setState(() {
        _error   = e.response?.data?['error'] ?? 'Prediction failed.';
        _loading = false;
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Prediction'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.purple.withOpacity(0.3)),
            ),
            child: const Text('AI', style: TextStyle(
              color: AppColors.purple, fontWeight: FontWeight.bold,
              fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
 
          // ── Input section ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Stock Ticker',
                  hint:  'e.g. RELIANCE.NS, INFY.NS, AAPL',
                  controller: _tickerCtrl,
                  prefixIcon: Icons.search,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                // Forecast days selector
                Row(children: [
                  const Text('Forecast days:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(width: 12),
                  ..._dayOptions.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('$d'),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                      selectedColor: AppColors.brand.withOpacity(0.2),
                      side: BorderSide(color: _days==d
                        ? AppColors.brand : AppColors.border),
                      labelStyle: TextStyle(color: _days==d
                        ? AppColors.brand : AppColors.textMuted,
                        fontWeight: _days==d
                          ? FontWeight.bold : FontWeight.normal),
                      backgroundColor: AppColors.bgInput,
                    ),
                  )).toList(),
                ]),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _predict,
                  icon: _loading
                    ? const SizedBox(width:18,height:18,
                        child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                    : const Icon(Icons.auto_graph),
                  label: Text(_loading ? 'Running models...' : 'Predict'),
                ),
              ],
            ),
          ),
 
          // ── Error ─────────────────────────────────────────
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Text(_error!,
                style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ),
 
          // ── Loading indicator ─────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running 5-model ensemble...',
                  style: TextStyle(color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('This may take 20–40 seconds',
                  style: TextStyle(
                    color: AppColors.textHint, fontSize: 12)),
              ]),
            ),
 
          // ── Results ───────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResults(_result!),
          ],
        ],
      ),
    );
  }
 
  Widget _buildResults(Map<String,dynamic> r) {
    final ticker      = r['ticker']        as String;
    final signal      = r['signal']        as String? ?? 'HOLD';
    final changePct   = (r['change_pct']   as num?)?.toDouble() ?? 0;
    final curPrice    = (r['current_price'] as num?)?.toDouble() ?? 0;
    final historical  = r['historical']    as Map<String,dynamic>? ?? {};
    final forecast    = r['forecast']      as Map<String,dynamic>? ?? {};
    final sentiment   = r['sentiment']     as Map<String,dynamic>?;
    final modelsUsed  = r['models_used']   as Map<String,dynamic>? ?? {};
    final accuracy    = r['accuracy']      as Map<String,dynamic>? ?? {};
 
    final histClose   = (historical['close'] as List? ?? []).cast<num>();
    final fcPrices    = (forecast['prices']      as List? ?? []).cast<num>();
    final fcUpper     = (forecast['bands_upper'] as List? ?? []).cast<num>();
    final fcLower     = (forecast['bands_lower'] as List? ?? []).cast<num>();
 
    // Signal colour
    final sigColor = signal == 'BUY'  ? AppColors.green
                   : signal == 'SELL' ? AppColors.red
                   : AppColors.orange;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
 
        // ── Ticker + Signal header ──────────────────────────
        Row(children: [
          Text(ticker, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold,
            color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal:12,vertical:5),
            decoration: BoxDecoration(
              color:        sigColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: sigColor.withOpacity(0.4)),
            ),
            child: Text(signal, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14,
              color: sigColor)),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_inr.format(curPrice), style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16,
              color: AppColors.textPrimary)),
            Text('${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 12,
                color: changePct >= 0 ? AppColors.green : AppColors.red)),
          ]),
        ]),
        const SizedBox(height: 20),
 
        // ── Forecast chart ──────────────────────────────────
        _ForecastChart(
          histClose: histClose,
          fcPrices:  fcPrices,
          fcUpper:   fcUpper,
          fcLower:   fcLower,
        ),
        const SizedBox(height: 8),
        // Legend
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegendDot(color: AppColors.brand, label: 'Historical'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.green, label: 'Forecast'),
          const SizedBox(width: 16),
          _LegendDot(
            color: AppColors.green.withOpacity(0.3),
            label: 'Confidence band'),
        ]),
        const SizedBox(height: 20),
 
        // ── Accuracy row ────────────────────────────────────
        if (accuracy.isNotEmpty)
          _InfoCard(
            title: 'Backtest Accuracy',
            icon:  Icons.analytics_outlined,
            child: Row(children: [
              _MiniStat(
                label: 'R²',
                value: '${(accuracy['r2_pct'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                color: AppColors.brand),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'RMSE',
                value: '${(accuracy['rmse'] as num?)?.toStringAsFixed(2) ?? '0'}',
                color: AppColors.textMuted),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Best model',
                value: accuracy['best_model'] as String? ?? '-',
                color: AppColors.purple),
            ]),
          ),
        const SizedBox(height: 16),
 
        // ── Model weights ────────────────────────────────────
        if (modelsUsed.isNotEmpty)
          _InfoCard(
            title: 'Model Weights (adaptive)',
            icon:  Icons.model_training,
            child: Column(
              children: modelsUsed.entries
                .toList()
                .map((e) {
                  final pct = (e.value as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      SizedBox(
                        width: 70,
                        child: Text(e.key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary)),
                      ),
                      Expanded(child: Stack(children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(3)),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.brand, AppColors.purple]),
                              borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                      ])),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  );
                }).toList(),
            ),
          ),
        const SizedBox(height: 16),
 
        // ── Sentiment ─────────────────────────────────────────
        if (sentiment != null)
          _SentimentCard(sentiment: sentiment),
      ],
    );
  }
}
 
// ── Forecast Line Chart ──────────────────────────────────────────
class _ForecastChart extends StatelessWidget {
  final List<num> histClose, fcPrices, fcUpper, fcLower;
  const _ForecastChart({
    required this.histClose, required this.fcPrices,
    required this.fcUpper,   required this.fcLower,
  });
 
  @override
  Widget build(BuildContext context) {
    // Use last 60 historical points to keep chart readable
    final hist   = histClose.length > 60
      ? histClose.sublist(histClose.length - 60) : histClose;
    final offset = hist.length.toDouble();
 
    // Convert to FlSpot lists
    List<FlSpot> toSpots(List<num> data, [double start = 0]) =>
      data.asMap().entries.map((e) =>
        FlSpot(start + e.key, e.value.toDouble())).toList();
 
    final histSpots  = toSpots(hist);
    final fcSpots    = toSpots(fcPrices, offset);
    final upperSpots = toSpots(fcUpper,  offset);
    final lowerSpots = toSpots(fcLower,  offset);
 
    // All values for Y axis range
    final allY = [...hist,...fcPrices,...fcUpper,...fcLower]
      .map((v) => v.toDouble()).toList();
    final minY = allY.reduce((a,b) => a < b ? a : b) * 0.99;
    final maxY = allY.reduce((a,b) => a > b ? a : b) * 1.01;
 
    return SizedBox(
      height: 240,
      child: LineChart(LineChartData(
        minY: minY, maxY: maxY,
        clipData: const FlClipData.all(),
        lineBarsData: [
          // Historical — solid blue
          LineChartBarData(
            spots:    histSpots,
            isCurved: true,
            color:    AppColors.brand,
            barWidth: 2,
            dotData:  const FlDotData(show: false),
            belowBarData: BarAreaData(
              show:  true,
              color: AppColors.brand.withOpacity(0.05),
            ),
          ),
          // Forecast — dashed green
          LineChartBarData(
            spots:     fcSpots,
            isCurved:  true,
            color:     AppColors.green,
            barWidth:  2,
            dotData:   const FlDotData(show: false),
            dashArray: [5, 4],
          ),
          // Upper confidence band
          LineChartBarData(
            spots:   upperSpots,
            color:   AppColors.green.withOpacity(0.25),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Lower confidence band
          LineChartBarData(
            spots:   lowerSpots,
            color:   AppColors.green.withOpacity(0.25),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.green.withOpacity(0.07),
              spotsLine: BarAreaSpotsLine(show: false),
            ),
          ),
        ],
        gridData:   FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:   AxisTitles(sideTitles:SideTitles(showTitles:false)),
          rightTitles: AxisTitles(sideTitles:SideTitles(showTitles:false)),
          bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
          leftTitles:  AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 60,
              getTitlesWidget: (v, _) => Text(
                v >= 1000 ? '${(v/1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted)),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) =>
              LineTooltipItem(
                '₹${s.y.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              )).toList(),
          ),
        ),
      )),
    );
  }
}
 
// ── Sentiment card ───────────────────────────────────────────────
class _SentimentCard extends StatelessWidget {
  final Map<String,dynamic> sentiment;
  const _SentimentCard({required this.sentiment});
 
  @override
  Widget build(BuildContext context) {
    final overall   = sentiment['overall']  as String? ?? 'neutral';
    final score     = (sentiment['score']   as num?)?.toDouble() ?? 0;
    final pos       = sentiment['pos_count'] as int? ?? 0;
    final neg       = sentiment['neg_count'] as int? ?? 0;
    final headlines = sentiment['headlines'] as List? ?? [];
    final color = overall == 'positive' ? AppColors.green
                : overall == 'negative' ? AppColors.red
                : AppColors.orange;
 
    return _InfoCard(
      title: 'News Sentiment',
      icon:  Icons.newspaper_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall badge
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(overall.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 12, color: color)),
            ),
            const SizedBox(width: 10),
            Text('Score: ${score >= 0 ? '+' : ''}${score.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Spacer(),
            Text('📈 $pos  📉 $neg',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 12),
          // Headlines
          ...headlines.take(5).map((h) {
            final item  = h as Map<String,dynamic>;
            final title = item['headline'] as String? ?? '';
            final sc    = (item['score']   as num?)?.toDouble() ?? 0;
            final sent  = item['sentiment'] as String? ?? 'neutral';
            final dot   = sent == 'positive' ? AppColors.green
                        : sent == 'negative' ? AppColors.red
                        : AppColors.textMuted;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary,
                        height: 1.4)),
                      Text(
                        'Score: ${sc >= 0 ? '+' : ''}${sc.toStringAsFixed(3)}',
                        style: TextStyle(fontSize: 10,
                          color: sc >= 0 ? AppColors.green : AppColors.red)),
                    ],
                  )),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
 
// ── Shared helper widgets ────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title; final IconData icon; final Widget child;
  const _InfoCard({required this.title,required this.icon,required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold,
            fontSize: 15, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
 
class _MiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _MiniStat({required this.label,required this.value,required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold,
        fontSize: 16, color: color)),
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textMuted)),
    ]);
  }
}
 
class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width:10,height:10,
        decoration:BoxDecoration(color:color,shape:BoxShape.circle)),
      const SizedBox(width:4),
      Text(label,style:const TextStyle(fontSize:10,color:AppColors.textMuted)),
    ]);
  }
}
