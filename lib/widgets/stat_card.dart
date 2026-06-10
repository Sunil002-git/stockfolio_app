import 'package:flutter/material.dart';
import '../core/theme.dart';
 
// StatCard — the coloured metric card used on the Dashboard.
// Shows an icon, a label, and a formatted value.
//
// Usage:
//   StatCard(
//     label: 'Balance',
//     value: '₹12,450.75',
//     icon:  Icons.account_balance_wallet_outlined,
//     color: AppColors.brand,
//   )
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color  color;
  final bool   isPositive; // controls value text colour
 
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isPositive = true,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width:  40, height: 40,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.12),
              shape:  BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color:    AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.bold,
                    color:      color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
