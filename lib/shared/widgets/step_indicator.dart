import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Step indicator cho Booking wizard (5 bước)
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Progress line + circles
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final stepIndex = index ~/ 2;
                final isDone = stepIndex < currentStep - 1;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppTheme.stepDone : AppTheme.stepPending,
                  ),
                );
              } else {
                // Circle
                final stepNum = index ~/ 2 + 1;
                final isActive = stepNum == currentStep;
                final isDone = stepNum < currentStep;
                return _StepCircle(
                  stepNum: stepNum,
                  isActive: isActive,
                  isDone: isDone,
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            children: List.generate(stepLabels.length, (i) {
              final isActive = i + 1 == currentStep;
              final isDone = i + 1 < currentStep;
              return Expanded(
                child: Text(
                  stepLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppTheme.primary
                        : isDone
                            ? AppTheme.stepDone
                            : AppTheme.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepNum;
  final bool isActive;
  final bool isDone;

  const _StepCircle({
    required this.stepNum,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    if (isDone) {
      bg = AppTheme.stepDone;
      textColor = Colors.white;
    } else if (isActive) {
      bg = AppTheme.stepActive;
      textColor = Colors.white;
    } else {
      bg = AppTheme.stepPending;
      textColor = AppTheme.textHint;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 32 : 28,
      height: isActive ? 32 : 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: isActive ? AppTheme.cardShadow : null,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '$stepNum',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
