import 'package:flutter/material.dart';
import '../core/theme.dart';
 
// TradeGroup — one position per symbol.
// Matches Django TradeGroup model exactly.
class TradeGroup {
  final int     id;
  final String  symbol;
  final String  segment;
  final String  exchange;
  final int     totalQuantity;
  final double  avgCost;
  final bool    isClosed;
  final double  totalInvested;
  final double? unrealizedPl;  // null for closed positions
  final double  realizedPl;
  final int?    brokerId;
  final String? brokerName;
 
  const TradeGroup({
    required this.id,
    required this.symbol,
    required this.segment,
    required this.exchange,
    required this.totalQuantity,
    required this.avgCost,
    required this.isClosed,
    required this.totalInvested,
    this.unrealizedPl,
    required this.realizedPl,
    this.brokerId,
    this.brokerName,
  });
 
  factory TradeGroup.fromJson(Map<String, dynamic> j) {
    return TradeGroup(
      id:             j['id']             as int,
      symbol:         j['symbol']         as String,
      segment:        j['segment']        as String,
      exchange:       j['exchange']       as String,
      totalQuantity:  j['total_quantity'] as int,
      avgCost:       (j['avg_cost']       as num).toDouble(),
      isClosed:       j['is_closed']      as bool,
      totalInvested: (j['total_invested'] as num).toDouble(),
      unrealizedPl:  (j['unrealized_pl']  as num?)?.toDouble(),
      realizedPl:    (j['realized_pl']    as num?)?.toDouble() ?? 0.0,
      brokerId:       j['broker_id']      as int?,
      brokerName:     j['broker_name']    as String?,
    );
  }
 
  // Segment display label and colour
  String get segmentLabel {
    const labels = {
      'equity':  'Equity',
      'futures': 'Futures',
      'ce':      'CE',
      'pe':      'PE',
      'mf':      'MF',
    };
    return labels[segment] ?? segment.toUpperCase();
  }
 
  Color get segmentColor {
    switch (segment) {
      case 'equity':  return AppColors.brand;
      case 'futures': return AppColors.orange;
      case 'ce':      return AppColors.green;
      case 'pe':      return AppColors.red;
      case 'mf':      return AppColors.purple;
      default:        return AppColors.textMuted;
    }
  }
}
