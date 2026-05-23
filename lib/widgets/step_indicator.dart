import 'package:flutter/material.dart';
import '../core/theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? labels; //optional label below each dot

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isComplete = i < currentStep;

        return Row(
          children: [
            // Connector line between steps (not before first)
            if (i > 0)
              Container(
                width: 32,
                height: 2,
                color: isComplete 
                ? AppColors.brand 
                : AppColors.border,
              ),

              // Step dot
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 32 : 24,
                    height: isActive? 32 : 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                      ? AppColors.brand
                      : isComplete
                        ? AppColors.green
                        : AppColors.bgInput,
                      border: Border.all(
                        color: isActive
                        ? AppColors.brand
                        : isComplete
                          ? AppColors.green
                          : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isComplete
                      ? const Icon(Icons.check,
                        size: 14, color: Colors.white)
                      : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: isActive ? 13 : 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                            ? Colors.white
                            : AppColors.textMuted,
                        ),
                      ),
                      ),
                      ),
                      if (labels != null && i < labels!.length) ...[
                        const SizedBox(height: 4),
                        Text(
                          labels![i],
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                              ? AppColors.brand
                              : AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
              ),
          ],
        );
      }),
    );
  }
}
