import 'package:flutter/material.dart';

import '../models/performance_tracker.dart';

class WeakAreaPanel extends StatelessWidget {
  final PerformanceTracker tracker;

  const WeakAreaPanel({super.key, required this.tracker});

  @override
  Widget build(BuildContext context) {
    final weakAreas = tracker.getAreasNeedingPractice();
    if (weakAreas.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Text(
                'Areas Needing Practice',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...weakAreas.map((area) => _WeakAreaTile(performance: area)),
        ],
      ),
    );
  }
}

class _WeakAreaTile extends StatelessWidget {
  final TopicPerformance performance;

  const _WeakAreaTile({required this.performance});

  @override
  Widget build(BuildContext context) {
    final accuracy = (performance.accuracy * 100).toInt();
    final color = performance.isWeak ? Colors.red : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$accuracy%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color.shade800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.topic,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  '${performance.totalAttempts} attempts · '
                  'Avg ${performance.avgTimeSeconds.toInt()}s · '
                  '${performance.avgHintsUsed.toStringAsFixed(1)} hints/q',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Accuracy bar
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: performance.accuracy,
                backgroundColor: Colors.red.shade100,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
