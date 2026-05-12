import 'package:flutter/material.dart';

import '../data/algebrica_questions.dart';
import '../data/mock_questions.dart';
import '../main.dart';
import '../models/performance_tracker.dart';
import '../models/practice_mode.dart';
import '../models/premium_state.dart';
import '../models/question_data.dart';
import '../models/revision_manager.dart';
import '../widgets/premium_gate.dart';
import 'foundation_journey_screen.dart';
import 'question_screen.dart';
import 'topic_synopsis_screen.dart';
import 'topic_revision_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PerformanceTracker _tracker = PerformanceTracker();
  final PremiumState _premiumState = PremiumState();
  final RevisionManager _revisionManager = RevisionManager();
  PracticeMode _selectedMode = PracticeMode.learner;

  @override
  void initState() {
    super.initState();
    _loadJourneyProgress();
  }

  Future<void> _loadJourneyProgress() async {
    await _tracker.loadAttempts();
    setState(() {}); // Refresh UI after loading progress
  }

  void _startPractice() {
    if (_selectedMode == PracticeMode.foundationJourney) {
      _startFoundationJourney();
      return;
    }

    // Combine all questions for now
    final allQuestions = [...mockQuestions, ...algebricaQuestions];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          questions: allQuestions,
          tracker: _tracker,
          premiumState: _premiumState,
          revisionManager: _revisionManager,
          practiceMode: _selectedMode,
        ),
      ),
    );
  }

  void _startFoundationJourney() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoundationJourneyScreen(
          journeyId: 'geometry_foundation_journey', // Load from content
          tracker: _tracker,
          premiumState: _premiumState,
        ),
      ),
    );
  }

  void _startTopicCapsule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicSynopsisScreen(
          topicId: 'math.geometry.central_angle_regular_polygon',
          tracker: _tracker,
          premiumState: _premiumState,
        ),
      ),
    );
  }

  void _startRevision() {
    final dueIds = _revisionManager.dueItems.map((i) => i.questionId).toSet();
    final dueQuestions =
        mockQuestions.where((q) => dueIds.contains(q.id)).toList();
    if (dueQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions due for revision!')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          questions: dueQuestions,
          tracker: _tracker,
          premiumState: _premiumState,
          revisionManager: _revisionManager,
          isRevisionMode: true,
        ),
      ),
    );
  }

  void _startTopicRevision() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicRevisionScreen(
          questions: mockQuestions,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // Theme toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, child) {
                      final isDark = mode == ThemeMode.dark;
                      return IconButton(
                        onPressed: () {
                          themeNotifier.value =
                              isDark ? ThemeMode.light : ThemeMode.dark;
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark
                              ? Colors.amber.shade400
                              : Colors.grey.shade700,
                        ),
                        tooltip: isDark
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
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
                  'From Class 7 basics to JEE-level thinking, one visual step at a time',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Topic Capsule HERO (primary CTA for Class 7 students)
                _TopicCapsuleHero(
                  onStartTopicCapsule: _startTopicCapsule,
                ),
                const SizedBox(height: 16),

                // Diagram preview (secondary)
                if (mockQuestions.isNotEmpty) ...[
                  _DiagramPreviewCard(question: mockQuestions.first),
                  const SizedBox(height: 16),
                ],

                // Feature chips (compact)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FeatureChip(
                        icon: Icons.visibility, label: 'Visual Reasoning'),
                    _FeatureChip(
                        icon: Icons.route, label: 'Foundation Journey'),
                    _FeatureChip(icon: Icons.healing, label: 'Smart Rescue'),
                    _FeatureChip(icon: Icons.trending_up, label: 'Diagnosis'),
                    _FeatureChip(icon: Icons.replay, label: 'Revision Mastery'),
                  ],
                ),

                const SizedBox(height: 16),

                // Revision nudge
                ListenableBuilder(
                  listenable: _revisionManager,
                  builder: (context, _) {
                    final dueCount = _revisionManager.dueCount;
                    final mastered = _revisionManager.masteredItems.length;
                    if (dueCount == 0 && mastered == 0) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        if (dueCount > 0)
                          GestureDetector(
                            onTap: _startRevision,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade50,
                                    Colors.deepPurple.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.purple.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.replay,
                                        size: 20,
                                        color: Colors.purple.shade700),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$dueCount question${dueCount > 1 ? 's' : ''} to revise today',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.purple.shade800,
                                          ),
                                        ),
                                        Text(
                                          '~${_revisionManager.estimatedMinutes} min · Tap to start',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.purple.shade400),
                                ],
                              ),
                            ),
                          ),
                        if (mastered > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  '$mastered question${mastered > 1 ? 's' : ''} mastered',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Premium tier toggle
                ListenableBuilder(
                  listenable: _premiumState,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _premiumState.isPremium
                            ? LinearGradient(colors: [
                                Colors.amber.shade50,
                                Colors.orange.shade50,
                              ])
                            : null,
                        color: _premiumState.isPremium
                            ? null
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _premiumState.isPremium
                              ? Colors.amber.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_premiumState.isPremium)
                            const PremiumBadge()
                          else
                            Icon(Icons.lock_outline,
                                size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _premiumState.isPremium
                                      ? 'Premium Active'
                                      : 'Free Tier',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _premiumState.isPremium
                                        ? Colors.amber.shade900
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  _premiumState.isPremium
                                      ? 'All features unlocked'
                                      : 'Upgrade for insights, drawing & more',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _premiumState.isPremium
                                        ? Colors.amber.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _premiumState.isPremium,
                            onChanged: (_) {
                              _premiumState.toggle();
                              setState(() {});
                            },
                            activeTrackColor: Colors.amber.shade200,
                            thumbColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.amber.shade700;
                              }
                              return null;
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Practice Mode Selector (Foundation Journey prioritized)
                Column(
                  children: [
                    // Primary: Foundation Journey
                    _ModeChip(
                      label: 'Foundation Journey',
                      icon: Icons.route,
                      isSelected:
                          _selectedMode == PracticeMode.foundationJourney,
                      color: Colors.green,
                      onTap: () => setState(
                          () => _selectedMode = PracticeMode.foundationJourney),
                      isFullWidth: true,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 8),
                    // Secondary modes
                    Row(
                      children: [
                        Expanded(
                          child: _ModeChip(
                            label: 'Learner',
                            icon: Icons.school,
                            isSelected: _selectedMode == PracticeMode.learner,
                            color: Colors.blue,
                            onTap: () => setState(
                                () => _selectedMode = PracticeMode.learner),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModeChip(
                            label: 'Mock Exam',
                            icon: Icons.timer,
                            isSelected: _selectedMode == PracticeMode.mockExam,
                            color: Colors.red,
                            onTap: () => setState(
                                () => _selectedMode = PracticeMode.mockExam),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModeChip(
                            label: 'Revision',
                            icon: Icons.replay,
                            isSelected: _selectedMode == PracticeMode.revision,
                            color: Colors.purple,
                            onTap: () => setState(
                                () => _selectedMode = PracticeMode.revision),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Flexible(
                      flex: 3,
                      fit: FlexFit.loose,
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _selectedMode == PracticeMode.revision
                              ? _startRevision
                              : _startPractice,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            _selectedMode == PracticeMode.foundationJourney
                                ? 'Start Foundation Journey'
                                : 'Practice with Interactive Diagrams (${mockQuestions.length + algebricaQuestions.length})',
                            style: const TextStyle(fontSize: 15),
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
                const SizedBox(height: 12),

                // Topic Revision Button with Animations
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _startTopicRevision,
                    icon: const Icon(Icons.animation),
                    label: const Text(
                      'Revise Topics with Animations',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
            child: Icon(Icons.schema, size: 28, color: Colors.indigo.shade600),
          ),
          const SizedBox(width: 12),
          Flexible(
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
                      _miniChip('~${question.estimatedSeconds}s', Colors.grey),
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
        color: color.withOpacity(0.15),
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

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
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
          Flexible(
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
                backgroundColor: color.withOpacity(0.15),
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

class _TopicCapsuleHero extends StatelessWidget {
  final VoidCallback onStartTopicCapsule;

  const _TopicCapsuleHero({required this.onStartTopicCapsule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_stories,
                  size: 28,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Topic Capsule',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Read. Understand. Practice. Master.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: onStartTopicCapsule,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Topic Capsule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Show topic capsule info
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Learn more about Topic Capsules'),
                      ),
                    );
                  },
                  icon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  label: Text(
                    'Learn More',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroFeature(
                icon: Icons.school,
                label: 'Class 7 Start',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _HeroFeature(
                icon: Icons.trending_up,
                label: 'Step-by-Step',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _HeroFeature(
                icon: Icons.emoji_events,
                label: 'JEE Bridge',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _HeroFeature({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;
  final bool isPrimary;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final containerWidth = isFullWidth ? double.infinity : null;

    if (isPrimary) {
      // Primary Foundation Journey chip style
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: containerWidth,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Regular mode chip style
    return Material(
      color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20, color: isSelected ? color : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
