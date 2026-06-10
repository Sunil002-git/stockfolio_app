import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/trade_group.dart';
 
final _inr = NumberFormat.currency(
  locale: 'en_IN', symbol: '₹', decimalDigits: 2);
String fmtInr(double v) => _inr.format(v);
 
class PositionCard extends StatelessWidget {
  final TradeGroup  position;
  final VoidCallback? onSell; // null = no sell button (closed position)
 
  const PositionCard({
    super.key,
    required this.position,
    this.onSell,
  });
 
  @override
  Widget build(BuildContext context) {
    final pos    = position;
    final pl     = pos.isClosed ? pos.realizedPl : (pos.unrealizedPl ?? 0.0);
    final isProfit = pl >= 0;
    final plColor  = isProfit ? AppColors.green : AppColors.red;
    final plLabel  = pos.isClosed ? 'Realized P&L' : 'Unrealized P&L';
 
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ── Header row: symbol + badges + sell button ──
            Row(
              children: [
                // Symbol
                Expanded(
                  child: Text(
                    pos.symbol,
                    style: const TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.bold,
                      color:      AppColors.textPrimary,
                    ),
                  ),
                ),
                // Segment badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        pos.segmentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:       Border.all(
                      color: pos.segmentColor.withOpacity(0.4)),
                  ),
                  child: Text(pos.segmentLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pos.segmentColor)),
                ),
                // Exchange tag
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(pos.exchange,
                    style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
                ),
                // Sell button (only for open positions)
                if (onSell != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSell,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: BorderSide(color: AppColors.red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Sell',
                      style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
 
            // ── Stats row ─────────────────────────────────────
            Row(
              children: [
                _Stat(label: 'Qty',      value: '${pos.totalQuantity}'),
                _Stat(label: 'Avg Cost', value: fmtInr(pos.avgCost)),
                _Stat(label: 'Invested', value: fmtInr(pos.totalInvested)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(plLabel,
                        style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        '${isProfit ? "+" : ""}${fmtInr(pl)}',
                        style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.bold,
                          color:      plColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
 
            // ── Broker tag (if broker assigned) ───────────────
            if (pos.brokerName != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.business_outlined,
                  size: 12, color: AppColors.purple.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(pos.brokerName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.purple.withOpacity(0.9))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
 
// Small label+value stat column
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: const TextStyle(
              fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
