import 'package:flutter/material.dart';
import '../models/performance_tracker.dart';
import '../models/premium_state.dart';
import '../models/foundation_journey.dart';
import '../models/journey_progression_engine.dart';
import '../models/journey_state.dart';
import '../models/student_profile.dart';
import '../services/journey_persistence.dart';
import 'foundation_journey_question_screen.dart';

class FoundationJourneyScreen extends StatefulWidget {
  final String journeyId;
  final PerformanceTracker tracker;
  final PremiumState premiumState;

  const FoundationJourneyScreen({
    super.key,
    required this.journeyId,
    required this.tracker,
    required this.premiumState,
  });

  @override
  State<FoundationJourneyScreen> createState() =>
      _FoundationJourneyScreenState();
}

class _FoundationJourneyScreenState extends State<FoundationJourneyScreen> {
  late JourneyProgressionEngine _engine;
  late Future<FoundationJourney> _journeyFuture;
  late StudentJourneyState _studentState;
  late StudentProfile _studentProfile;
  final JourneyPersistence _persistence = JourneyPersistence();
  bool _isLoadingState = true;

  @override
  void initState() {
    super.initState();
    _engine = JourneyProgressionEngine();
    _journeyFuture = _engine.loadJourney(widget.journeyId);

    // Create default student profile
    _studentProfile = StudentProfile(
      studentId: 'demo_student',
      name: 'Student',
      currentClass: 7,
      targetExam: TargetExam.jeeMain,
      comfortLevel: ComfortLevel.beginner,
    );

    _studentState =
        _engine.getStudentState(_studentProfile.studentId, widget.journeyId);

    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final savedState = await _persistence.loadJourneyState(widget.journeyId);
    if (savedState != null && mounted) {
      setState(() {
        _studentState = savedState;
        _isLoadingState = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingState = false);
    }

    final savedProfile = await _persistence.loadStudentProfile();
    _studentProfile = StudentProfile(
      studentId: savedProfile.studentId,
      name: savedProfile.name,
      currentClass: 7,
      targetExam: TargetExam.jeeMain,
      comfortLevel: ComfortLevel.beginner,
    );
  }

  Future<void> _saveState() async {
    await _persistence.saveJourneyState(_studentState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foundation Journey'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<FoundationJourney>(
        future: _journeyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildErrorState('Journey not found');
          }

          final journey = snapshot.data!;
          return _buildJourneyContent(journey);
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
              'Unable to load Foundation Journey',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() {
                  _journeyFuture = _engine.loadJourney(widget.journeyId);
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyContent(FoundationJourney journey) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journey Header
          _JourneyHeader(journey: journey),
          const SizedBox(height: 24),

          // Progress Overview
          _ProgressOverview(
            journey: journey,
            studentState: _studentState,
          ),
          const SizedBox(height: 24),

          // Current Level
          _CurrentLevelSection(
            journey: journey,
            studentState: _studentState,
            onStartLevel: _startLevel,
          ),
          const SizedBox(height: 24),

          // Level Progression
          _LevelProgression(
            journey: journey,
            studentState: _studentState,
            onLevelTap: _navigateToLevel,
          ),
          const SizedBox(height: 24),

          // Journey Info
          _JourneyInfo(journey: journey),
        ],
      ),
    );
  }

  void _startLevel(int levelIndex) async {
    try {
      final journey = await _journeyFuture;
      final level = journey.levels[levelIndex];

      // Show micro-lesson if available
      if (level.microLesson.title.isNotEmpty) {
        await _showMicroLesson(level.microLesson);
      }

      // Navigate to questions for this level
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoundationJourneyQuestionScreen(
              level: level,
              levelIndex: levelIndex,
              journey: journey,
              studentState: _studentState,
              engine: _engine,
              tracker: widget.tracker,
              premiumState: widget.premiumState,
            ),
          ),
        );
        // Save progress after returning from question screen
        await _saveState();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start level: $e')),
        );
      }
    }
  }

  void _navigateToLevel(int levelIndex) {
    // Allow navigation to completed levels or current level
    if (levelIndex <= _studentState.currentLevelIndex) {
      _startLevel(levelIndex);
    }
  }

  Future<void> _showMicroLesson(MicroLesson microLesson) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(microLesson.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(microLesson.body),
                const SizedBox(height: 16),
                if (microLesson.visualHintIds.isNotEmpty) ...[
                  Text(
                    'Visual Hints:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...microLesson.visualHintIds.map((hint) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(hint)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  final FoundationJourney journey;

  const _JourneyHeader({required this.journey});

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
                Icons.route,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      journey.subtitle,
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
                icon: Icons.school,
                label: journey.targetGrade,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.emoji_events,
                label: journey.targetExam,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule,
                label: '${journey.estimatedDurationMinutes} min',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final FoundationJourney journey;
  final StudentJourneyState studentState;

  const _ProgressOverview({
    required this.journey,
    required this.studentState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedLevels = studentState.levelStates.values
        .where((state) => state == LevelState.mastered)
        .length;
    final progress = completedLevels / journey.levels.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                'Your Progress',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '$completedLevels/${journey.levels.length} levels',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% Complete',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CurrentLevelSection extends StatelessWidget {
  final FoundationJourney journey;
  final StudentJourneyState studentState;
  final Function(int) onStartLevel;

  const _CurrentLevelSection({
    required this.journey,
    required this.studentState,
    required this.onStartLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = journey.levels[studentState.currentLevelIndex];
    final levelState =
        studentState.getLevelState(studentState.currentLevelIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      currentLevel.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _LevelStateChip(state: levelState),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentLevel.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onStartLevel(studentState.currentLevelIndex),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                levelState == LevelState.notStarted
                    ? 'Start Level'
                    : 'Continue Level',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelProgression extends StatelessWidget {
  final FoundationJourney journey;
  final StudentJourneyState studentState;
  final Function(int) onLevelTap;

  const _LevelProgression({
    required this.journey,
    required this.studentState,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey Path',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...journey.levels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final state = studentState.getLevelState(index);
          final isCurrent = index == studentState.currentLevelIndex;
          final canAccess = index <= studentState.currentLevelIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              level: level,
              levelIndex: index,
              state: state,
              isCurrent: isCurrent,
              canAccess: canAccess,
              onTap: () => onLevelTap(index),
            ),
          );
        }),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final JourneyLevel level;
  final int levelIndex;
  final LevelState state;
  final bool isCurrent;
  final bool canAccess;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.levelIndex,
    required this.state,
    required this.isCurrent,
    required this.canAccess,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: canAccess ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primary.withOpacity(0.1)
              : canAccess
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? theme.colorScheme.primary
                : canAccess
                    ? theme.colorScheme.outline.withOpacity(0.2)
                    : theme.colorScheme.outline.withOpacity(0.1),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getLevelColor(state, theme),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getLevelIcon(state),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: canAccess
                          ? null
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '${level.classLevel} • ${level.role}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (!canAccess)
              Icon(
                Icons.lock,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(LevelState state, ThemeData theme) {
    switch (state) {
      case LevelState.mastered:
        return Colors.green;
      case LevelState.inProgress:
        return theme.colorScheme.primary;
      case LevelState.needsPractice:
        return Colors.orange;
      case LevelState.notStarted:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(LevelState state) {
    switch (state) {
      case LevelState.mastered:
        return Icons.check;
      case LevelState.inProgress:
        return Icons.play_arrow;
      case LevelState.needsPractice:
        return Icons.refresh;
      case LevelState.notStarted:
        return Icons.lock_outline;
    }
  }
}

class _JourneyInfo extends StatelessWidget {
  final FoundationJourney journey;

  const _JourneyInfo({required this.journey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Journey',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This foundation journey takes you step-by-step from Class ${journey.targetGrade} concepts to JEE-level problem solving. Each level builds on the previous one, ensuring you master each concept before moving forward.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelStateChip extends StatelessWidget {
  final LevelState state;

  const _LevelStateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    String label;

    switch (state) {
      case LevelState.mastered:
        color = Colors.green;
        label = 'Mastered';
        break;
      case LevelState.inProgress:
        color = theme.colorScheme.primary;
        label = 'In Progress';
        break;
      case LevelState.needsPractice:
        color = Colors.orange;
        label = 'Needs Practice';
        break;
      case LevelState.notStarted:
        color = Colors.grey;
        label = 'Not Started';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
