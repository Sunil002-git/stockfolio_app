import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/broker_provider.dart';
 
// BrokerSelectorBar — horizontal scrollable broker pills.
// Equivalent to the <BrokerSelector> component in the React web app.
//
// Shows nothing if the user has no brokers (returns SizedBox.shrink()).
// This means it is safe to place at the top of every main screen.
class BrokerSelectorBar extends StatelessWidget {
  const BrokerSelectorBar({super.key});
 
  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BrokerProvider>();
 
    // Hide if no brokers — do not show an empty bar
    if (bp.brokers.isEmpty) return const SizedBox.shrink();
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:  AppColors.bgCard,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Building icon
          const Icon(Icons.business_outlined,
            size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          // Scrollable pill row
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All Brokers" pill
                  _BrokerPill(
                    label:    'All Brokers',
                    isActive: bp.activeBrokerId == null,
                    onTap:    () => bp.setActiveBroker(null),
                  ),
                  // One pill per broker
                  ...bp.brokers.map((broker) => _BrokerPill(
                    label:    broker.name,
                    isActive: bp.activeBrokerId == broker.id,
                    onTap:    () => bp.setActiveBroker(broker.id),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// Private pill widget — only used inside this file
class _BrokerPill extends StatelessWidget {
  final String label;
  final bool   isActive;
  final VoidCallback onTap; // VoidCallback = void Function()
 
  const _BrokerPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          onTap:       onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                ? AppColors.brand.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                  ? AppColors.brand
                  : Colors.white.withOpacity(0.1),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: isActive
                  ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                  ? AppColors.brand : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
