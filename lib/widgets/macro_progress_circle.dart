// En: lib/widgets/macro_progress_circle.dart

import 'package:flutter/material.dart';

class MacroProgressCircle extends StatelessWidget {
  final String title;
  final double percentage; // Un valor entre 0.0 y 1.0
  final Color progressColor;
  final String emoji;

  const MacroProgressCircle({
    super.key,
    required this.title,
    required this.percentage,
    required this.progressColor,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              Center(
                child: Text(
                  "${(percentage * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$emoji $title",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
