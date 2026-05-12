import 'package:flutter/material.dart';
import '../models/drill_session.dart';
import '../models/topic_mastery.dart';
import '../services/mastery_tracker.dart';
import '../services/attempt_tracker.dart';
import '../services/reinforcement_selector.dart';
import '../services/topic_content_loader.dart';

class WeaknessReportScreen extends StatefulWidget {
  final String topicId;
  final DrillSession? session;

  const WeaknessReportScreen({
    super.key,
    required this.topicId,
    this.session,
  });

  @override
  State<WeaknessReportScreen> createState() => _WeaknessReportScreenState();
}

class _WeaknessReportScreenState extends State<WeaknessReportScreen> {
  TopicMastery? _topicMastery;
  Map<String, int> _misconceptions = {};
  Map<String, dynamic> _topicStats = {};
  List<String> _weakConcepts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeaknessData();
  }

  Future<void> _loadWeaknessData() async {
    setState(() => _isLoading = true);

    try {
      // Load topic mastery
      _topicMastery = await MasteryTracker.getTopicMastery(widget.topicId);
      
      // Load topic statistics
      _topicStats = await AttemptTracker.getTopicStats(widget.topicId);
      
      // Load misconceptions for this topic
      _misconceptions = await AttemptTracker.getMisconceptionsForTopic(widget.topicId);
      
      // Get weak concepts
      _weakConcepts = await MasteryTracker.getWeakConcepts(widget.topicId);
      
    } catch (e) {
      debugPrint('Error loading weakness data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Weakness Report'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your performance...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weakness Report'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeaknessData,
            tooltip: 'Refresh Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Performance Card
            _buildPerformanceCard(theme),
            
            const SizedBox(height: 20),
            
            // Accuracy Trend Card
            _buildAccuracyCard(theme),
            
            const SizedBox(height: 20),
            
            // Misconceptions Card
            if (_misconceptions.isNotEmpty) ...[
              _buildMisconceptionsCard(theme),
              const SizedBox(height: 20),
            ],
            
            // Weak Concepts Card
            if (_weakConcepts.isNotEmpty) ...[
              _buildWeakConceptsCard(theme),
              const SizedBox(height: 20),
            ],
            
            // Recommendations Card
            _buildRecommendationsCard(theme),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(ThemeData theme) {
    final accuracy = _topicStats['accuracy'] as double? ?? 0.0;
    final totalAttempts = _topicStats['totalAttempts'] as int? ?? 0;
    final averageTime = _topicStats['averageTime'] as double? ?? 0.0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overall Performance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Circular progress indicator for accuracy
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: accuracy,
                        strokeWidth: 6,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(
                          accuracy >= 0.8
                              ? Colors.green
                              : accuracy >= 0.6
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(accuracy * 100).toInt()}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Accuracy',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        'Total Attempts',
                        '$totalAttempts',
                        Icons.quiz,
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Average Time',
                        '${averageTime.toStringAsFixed(1)}s',
                        Icons.timer,
                        theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Mastery Level',
                        _topicMastery != null 
                            ? MasteryTracker.getMasteryLevel(_topicMastery!.masteryScore)
                            : 'Not Started',
                        Icons.emoji_events,
                        _getMasteryColor(accuracy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(ThemeData theme) {
    final correctCount = _topicStats['correctCount'] as int? ?? 0;
    final totalCount = _topicStats['totalAttempts'] as int? ?? 0;
    final incorrectCount = totalCount - correctCount;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accuracy Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Accuracy bars
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalCount > 0 ? correctCount / totalCount : 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correct: $correctCount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalCount > 0 ? incorrectCount / totalCount : 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wrong: $incorrectCount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMisconceptionsCard(ThemeData theme) {
    final sortedMisconceptions = _misconceptions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Repeated Misconceptions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedMisconceptions.length} issues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...List.generate(
              sortedMisconceptions.length.clamp(0, 5),
              (index) {
                final entry = sortedMisconceptions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Occurred ${entry.value} times',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}x',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            if (sortedMisconceptions.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${sortedMisconceptions.length - 5} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeakConceptsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weak Concepts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_weakConcepts.length} concepts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weakConcepts.map((concept) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    concept,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(ThemeData theme) {
    final accuracy = _topicStats['accuracy'] as double? ?? 0.0;
    final recommendations = _generateRecommendations(accuracy);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    recommendation.icon,
                    color: recommendation.color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: recommendation.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.description,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startRecommendedDrill(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Recommended Drill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _startRevisionDrill(),
                icon: const Icon(Icons.refresh),
                label: const Text('Revision'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reviewSynopsis(),
                icon: const Icon(Icons.book),
                label: const Text('Review Synopsis'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getMasteryColor(double accuracy) {
    if (accuracy >= 0.9) return Colors.green;
    if (accuracy >= 0.8) return Colors.lightGreen;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  List<Recommendation> _generateRecommendations(double accuracy) {
    final recommendations = <Recommendation>[];
    
    if (accuracy < 0.6) {
      recommendations.add(Recommendation(
        title: 'Focus on Basics',
        description: 'Start with starter questions to build foundational understanding.',
        icon: Icons.school,
        color: Colors.red,
      ));
    }
    
    if (_misconceptions.isNotEmpty) {
      recommendations.add(Recommendation(
        title: 'Address Misconceptions',
        description: 'Practice questions targeting your repeated misconceptions.',
        icon: Icons.warning,
        color: Colors.orange,
      ));
    }
    
    if (_weakConcepts.isNotEmpty) {
      recommendations.add(Recommendation(
        title: 'Strengthen Weak Areas',
        description: 'Focus on concepts where you\'re struggling most.',
        icon: Icons.psychology,
        color: Colors.red,
      ));
    }
    
    if (accuracy >= 0.6 && accuracy < 0.8) {
      recommendations.add(Recommendation(
        title: 'Practice Mixed Questions',
        description: 'Try a mix of difficulties to improve consistency.',
        icon: Icons.shuffle,
        color: Colors.blue,
      ));
    }
    
    if (accuracy >= 0.8) {
      recommendations.add(Recommendation(
        title: 'Challenge Yourself',
        description: 'You\'re doing well! Try harder questions to reach mastery.',
        icon: Icons.trending_up,
        color: Colors.green,
      ));
    }
    
    return recommendations;
  }

  void _startRecommendedDrill() {
    // Navigate to quick drill with mode based on performance
    final accuracy = _topicStats['accuracy'] as double? ?? 0.0;
    
    if (accuracy < 0.6) {
      // Start with easier questions
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const QuickDrillScreen(
            topicId: 'math.geometry.central_angle_regular_polygon',
            mode: DrillMode.quickDrill,
          ),
        ),
      );
    } else {
      // Start revision drill
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const QuickDrillScreen(
            topicId: 'math.geometry.central_angle_regular_polygon',
            mode: DrillMode.revision,
          ),
        ),
      );
    }
  }

  void _startRevisionDrill() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const QuickDrillScreen(
          topicId: 'math.geometry.central_angle_regular_polygon',
          mode: DrillMode.revision,
        ),
      ),
    );
  }

  void _reviewSynopsis() {
    // Navigate to topic synopsis screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TopicSynopsisScreen(
          topicId: 'math.geometry.central_angle_regular_polygon',
        ),
      ),
    );
  }
}

class Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Import the screens that are referenced
class TopicSynopsisScreen extends StatelessWidget {
  final String topicId;

  const TopicSynopsisScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Synopsis'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Topic synopsis will be loaded here'),
      ),
    );
  }
}