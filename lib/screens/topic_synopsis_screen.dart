import 'package:flutter/material.dart';
import '../models/diagram_data.dart';
import '../models/performance_tracker.dart';
import '../models/premium_state.dart';
import '../models/practice_mode.dart';
import '../models/question_data.dart';
import '../models/revision_manager.dart';
import '../models/topic_capsule.dart';
import '../services/topic_content_loader.dart';
import '../widgets/diagram_manipulatives.dart';
import 'question_screen.dart';

class TopicSynopsisScreen extends StatefulWidget {
  final String topicId;
  final PerformanceTracker tracker;
  final PremiumState premiumState;

  const TopicSynopsisScreen({
    super.key,
    required this.topicId,
    required this.tracker,
    required this.premiumState,
  });

  @override
  State<TopicSynopsisScreen> createState() => _TopicSynopsisScreenState();
}

class _TopicSynopsisScreenState extends State<TopicSynopsisScreen> {
  late Future<TopicCapsule> _topicFuture;
  int _currentCardIndex = 0;
  bool _showPractice = false;

  @override
  void initState() {
    super.initState();
    _topicFuture = TopicContentLoader.loadTopicCapsule(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Capsule'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<TopicCapsule>(
        future: _topicFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildErrorState('Topic not found');
          }

          final topic = snapshot.data!;
          return _buildTopicContent(topic);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load Topic Capsule',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicContent(TopicCapsule topic) {
    if (_showPractice) {
      return _buildPracticeSection(topic);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Header
          _TopicHeader(topic: topic),
          const SizedBox(height: 24),

          // Synopsis Cards
          _SynopsisSection(
            topic: topic,
            currentIndex: _currentCardIndex,
            onNext: () => setState(() => _currentCardIndex++),
            onPrevious: () => setState(() => _currentCardIndex--),
          ),
          const SizedBox(height: 24),

          // Formula Section
          _FormulaSection(topic: topic),
          const SizedBox(height: 24),

          // Interactive Manipulatives
          if (topic.manipulatives.isNotEmpty) ...[
            _ManipulativesSection(topic: topic),
            const SizedBox(height: 24),
          ],

          // Common Mistakes
          _CommonMistakesSection(topic: topic),
          const SizedBox(height: 24),

          // Practice Button
          _PracticeButtonSection(
              topic: topic,
              onStartPractice: () {
                setState(() => _showPractice = true);
              }),
        ],
      ),
    );
  }

  Widget _buildPracticeSection(TopicCapsule topic) {
    return Column(
      children: [
        // Practice Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Time',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Apply what you learned',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
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
        const SizedBox(height: 16),

        // Question Types
        _QuestionTypeCard(
          title: 'Starter Questions',
          subtitle: 'Build your confidence',
          icon: Icons.school,
          color: Colors.green,
          questionIds: topic.starterQuestionIds,
          topic: topic,
          tracker: widget.tracker,
          premiumState: widget.premiumState,
        ),
        const SizedBox(height: 12),

        _QuestionTypeCard(
          title: 'Practice Questions',
          subtitle: 'Strengthen your understanding',
          icon: Icons.fitness_center,
          color: Colors.blue,
          questionIds: topic.practiceQuestionIds,
          topic: topic,
          tracker: widget.tracker,
          premiumState: widget.premiumState,
        ),
        const SizedBox(height: 12),

        _QuestionTypeCard(
          title: 'Challenge Questions',
          subtitle: 'Test your limits',
          icon: Icons.emoji_events,
          color: Colors.orange,
          questionIds: topic.challengeQuestionIds,
          topic: topic,
          tracker: widget.tracker,
          premiumState: widget.premiumState,
        ),

        const SizedBox(height: 16),

        // Back to Synopsis Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showPractice = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Synopsis'),
          ),
        ),
      ],
    );
  }
}

// Helper widgets for the topic capsule UI
class _TopicHeader extends StatelessWidget {
  final TopicCapsule topic;

  const _TopicHeader({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${topic.classLevel} • ${topic.targetExamBridge}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.schedule,
                label: '${topic.estimatedDurationMinutes} min',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.psychology,
                label: 'Interactive',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SynopsisSection extends StatelessWidget {
  final TopicCapsule topic;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _SynopsisSection({
    required this.topic,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = topic.synopsisCards[currentIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synopsis',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                '${currentIndex + 1}/${topic.synopsisCards.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
                  theme.colorScheme.secondaryContainer.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              TextButton.icon(
                onPressed: currentIndex < topic.synopsisCards.length - 1
                    ? onNext
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaSection extends StatelessWidget {
  final TopicCapsule topic;

  const _FormulaSection({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.functions,
                color: theme.colorScheme.onSecondaryContainer,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Formulae',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topic.formulae.map((formula) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formula,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ManipulativesSection extends StatefulWidget {
  final TopicCapsule topic;

  const _ManipulativesSection({required this.topic});

  @override
  State<_ManipulativesSection> createState() => _ManipulativesSectionState();
}

class _ManipulativesSectionState extends State<_ManipulativesSection> {
  final Map<String, dynamic> _manipulationValues = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Interactive Tools',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Create a dummy question for manipulatives
          DiagramManipulatives(
            question: QuestionData(
              id: 'dummy',
              text: 'Interactive demo',
              diagram: const DiagramData(
                id: 'dummy',
                type: DiagramType.geometry,
                elements: [],
              ),
              options: [],
              correctIndex: 0,
              subject: 'Mathematics',
              topic: widget.topic.title,
            ),
            availableManipulatives: widget.topic.manipulatives,
            onManipulationChange: (key, value) {
              _manipulationValues[key] = value;
            },
          ),
        ],
      ),
    );
  }
}

class _CommonMistakesSection extends StatelessWidget {
  final TopicCapsule topic;

  const _CommonMistakesSection({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: theme.colorScheme.onErrorContainer,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Common Mistakes',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topic.commonMistakes.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PracticeButtonSection extends StatelessWidget {
  final TopicCapsule topic;
  final VoidCallback onStartPractice;

  const _PracticeButtonSection({
    required this.topic,
    required this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.play_circle_filled,
            color: theme.colorScheme.onPrimary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to Practice?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Test your understanding with questions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartPractice,
              icon: const Icon(Icons.psychology),
              label: const Text('Start Practice'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.onPrimary,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> questionIds;
  final TopicCapsule topic;
  final PerformanceTracker tracker;
  final PremiumState premiumState;

  const _QuestionTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.questionIds,
    required this.topic,
    required this.tracker,
    required this.premiumState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _startQuestionSession(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${questionIds.length} questions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuestionSession(BuildContext context) async {
    try {
      // Load questions by their IDs
      final questions =
          await TopicContentLoader.loadQuestionsByIds(questionIds);

      if (!context.mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available')),
        );
        return;
      }

      // Navigate to question screen with loaded questions
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionScreen(
            questions: questions,
            tracker: tracker,
            premiumState: premiumState,
            revisionManager: RevisionManager(),
            practiceMode: PracticeMode.learner,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
