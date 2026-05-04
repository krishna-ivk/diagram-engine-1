import 'package:flutter/material.dart';

import '../data/mock_questions.dart';
import '../models/performance_tracker.dart';
import '../models/question_data.dart';
import 'question_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PerformanceTracker _tracker = PerformanceTracker();

  void _startPractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          questions: mockQuestions,
          tracker: _tracker,
        ),
      ),
    );
  }

  void _showPerformanceSummary() {
    final topics = _tracker.getTopicPerformance();
    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No practice data yet. Start solving!')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PerformanceSummary(
        topics: topics,
        weakAreas: _tracker.getAreasNeedingPractice(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.schema_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Diagram Engine',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive thinking tools for JEE preparation',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Feature cards
              _FeatureCard(
                icon: Icons.touch_app,
                title: 'Tap → Insight',
                description:
                    'Tap any element for contextual JEE hints',
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.assistant,
                title: 'Guide Me',
                description:
                    'Progressive hint system — think, don\'t just solve',
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.edit,
                title: 'Drawing Tools',
                description:
                    'Draw auxiliary lines, mark points, build constructions',
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.trending_up,
                title: 'Performance Tracking',
                description:
                    'Weak area detection, time tracking, smart insights',
              ),

              const Spacer(),

              // Diagram preview (first question)
              if (mockQuestions.isNotEmpty) ...[
                _DiagramPreviewCard(question: mockQuestions.first),
                const SizedBox(height: 16),
              ],

              // Buttons
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _startPractice,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          'Start Practice (${mockQuestions.length} Questions)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: OutlinedButton(
                      onPressed: _showPerformanceSummary,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.bar_chart),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagramPreviewCard extends StatelessWidget {
  final QuestionData question;

  const _DiagramPreviewCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          // Mini diagram icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child:
                Icon(Icons.schema, size: 28, color: Colors.indigo.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.diagram.title ?? 'Diagram Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.indigo.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _miniChip(question.subject, Colors.indigo),
                    const SizedBox(width: 4),
                    _miniChip(
                      question.difficulty == Difficulty.easy
                          ? 'Easy'
                          : question.difficulty == Difficulty.hard
                              ? 'Hard'
                              : 'Medium',
                      question.difficulty == Difficulty.easy
                          ? Colors.green
                          : question.difficulty == Difficulty.hard
                              ? Colors.red
                              : Colors.orange,
                    ),
                    if (question.estimatedSeconds != null) ...[
                      const SizedBox(width: 4),
                      _miniChip(
                          '~${question.estimatedSeconds}s', Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.indigo.shade400),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  final Map<String, TopicPerformance> topics;
  final List<TopicPerformance> weakAreas;

  const _PerformanceSummary({
    required this.topics,
    required this.weakAreas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Performance Summary',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          if (weakAreas.isNotEmpty) ...[
            Text(
              'Areas Needing Practice',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...weakAreas.map((area) => _TopicRow(
                  performance: area,
                  color: area.isWeak ? Colors.red : Colors.orange,
                )),
            const Divider(height: 24),
          ],
          Text(
            'All Topics',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: topics.values
                  .map((p) => _TopicRow(
                        performance: p,
                        color: p.isWeak
                            ? Colors.red
                            : p.needsPractice
                                ? Colors.orange
                                : Colors.green,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final TopicPerformance performance;
  final Color color;

  const _TopicRow({required this.performance, required this.color});

  @override
  Widget build(BuildContext context) {
    final accuracy = (performance.accuracy * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$accuracy%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${performance.totalAttempts} attempts · '
                  'Avg ${performance.avgTimeSeconds.toInt()}s',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: performance.accuracy,
                backgroundColor: color.withValues(alpha: 0.15),
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
