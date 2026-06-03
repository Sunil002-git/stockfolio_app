import 'package:flutter/material.dart';
import '../core/theme.dart';
 
class PlaceholderScreen extends StatelessWidget {
  final String   title;
  final IconData icon;
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.brand.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color:      AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in a future sprint',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
