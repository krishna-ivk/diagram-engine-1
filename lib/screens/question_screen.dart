import 'dart:async';

import 'package:flutter/material.dart';

import '../models/diagram_element.dart';
import '../models/performance_tracker.dart';
import '../models/practice_mode.dart';
import '../models/premium_state.dart';
import '../models/question_data.dart';
import '../models/revision_manager.dart';
import '../models/rescue_system.dart';
import '../models/concept_graph.dart';
import '../services/content_loader.dart';
import '../widgets/diagram_canvas.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/fullscreen_diagram.dart';
import '../widgets/insight_panel.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/premium_gate.dart';
import '../widgets/question_panel.dart';
import '../widgets/reveal_panel.dart';

class QuestionScreen extends StatefulWidget {
  final List<QuestionData> questions;
  final PerformanceTracker tracker;
  final PremiumState premiumState;
  final RevisionManager revisionManager;
  final bool isRevisionMode;
  final PracticeMode practiceMode;

  const QuestionScreen({
    super.key,
    required this.questions,
    required this.tracker,
    required this.premiumState,
    required this.revisionManager,
    this.isRevisionMode = false,
    this.practiceMode = PracticeMode.learner,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _showAnswer = false;

  bool _showValues = true;
  bool _showHints = false;
  bool _showLabels = true;

  final Set<String> _highlightedIds = {};
  DiagramElement? _lastTappedElement;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Smart auto-highlight
  Timer? _inactivityTimer;
  bool _autoHighlighted = false;

  // Drawing tools
  bool _drawingEnabled = false;
  DrawingTool _activeTool = DrawingTool.none;
  List<DrawnElement> _drawnElements = [];

  // Hints tracking
  int _hintsUsed = 0;
  int _tapCount = 0;

  // Page transition animations
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Local session questions (avoid mutating _sessionQuestions)
  late List<QuestionData> _sessionQuestions;

  QuestionData get _currentQuestion => _sessionQuestions[_currentIndex];
  PremiumTier get _tier => widget.premiumState.tier;

  // Mode-based feature control
  bool get _allowsHints => widget.practiceMode == PracticeMode.learner;
  bool get _allowsRevealSteps => widget.practiceMode == PracticeMode.learner;
  bool get _allowsConceptExplanation => widget.practiceMode == PracticeMode.learner;
  bool get _showTimer => widget.practiceMode == PracticeMode.mockExam;
  bool get _isRevisionMode => widget.practiceMode == PracticeMode.revision || widget.isRevisionMode;

  // Smart Rescue Flow
  bool _isRescueMode = false;
  QuestionData? _originalQuestion;
  List<RescueQuestion> _rescuePath = [];
  int _rescueIndex = 0;
  late RescueSystem _rescueSystem;
  late ConceptGraph _conceptGraph;

  String _getPrimaryConcept(QuestionData q) {
    // Use primaryConcept if available, fallback to coreConcept, then topic
    if (q.primaryConcept.isNotEmpty) return q.primaryConcept;
    if (q.coreConcept != null && q.coreConcept!.isNotEmpty) return q.coreConcept!;
    return q.topic;
  }

  String _getChapter(QuestionData q) {
    // Use chapter if available, fallback to topic
    if (q.chapter.isNotEmpty) return q.chapter;
    return q.topic;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize local session questions (avoid mutating widget.questions)
    _sessionQuestions = List.of(widget.questions);
    
    // Load curated content if available
    _loadCuratedContent();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
    _startTimer();
    
    // Initialize RescueSystem with default concept graph
    _conceptGraph = defaultConceptGraph;
    _rescueSystem = RescueSystem(
      allQuestions: _sessionQuestions,
      conceptGraph: _conceptGraph,
    );
  }
  
  /// Load curated content from JSON files
  Future<void> _loadCuratedContent() async {
    try {
      // Load geometry rescue ladder
      final rescueQuestions = await ContentLoader.loadGeometryRescueLadder();
      
      // Add rescue questions to session (they come first in the ladder)
      _sessionQuestions.insertAll(0, rescueQuestions);
      
      // Update RescueSystem with new questions
      _rescueSystem = RescueSystem(
        allQuestions: _sessionQuestions,
        conceptGraph: _conceptGraph,
      );
      
      setState(() {});
      print('Loaded ${rescueQuestions.length} rescue questions');
    } catch (e) {
      print('Error loading curated content: $e');
      // Continue with in-code questions if loading fails
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_showAnswer) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _autoHighlighted = false;
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (!_showAnswer && _highlightedIds.isEmpty && mounted &&
          PremiumFeatures.smartHighlighting(_tier)) {
        _autoHighlightRelevant();
      }
    });
  }

  void _autoHighlightRelevant() {
    final interactive = _currentQuestion.diagram.elements
        .where((e) => e.interactive && e.insight != null)
        .take(2);
    if (interactive.isNotEmpty) {
      setState(() {
        for (final el in interactive) {
          _highlightedIds.add(el.id);
        }
        _lastTappedElement = interactive.first;
        _autoHighlighted = true;
      });
    }
  }

  void _onElementTap(String id) {
    _tapCount++;
    _resetInactivityTimer();
    setState(() {
      if (_highlightedIds.contains(id)) {
        _highlightedIds.remove(id);
        _lastTappedElement = null;
      } else {
        _highlightedIds.add(id);
        _lastTappedElement = _currentQuestion.diagram.elements
            .where((e) => e.id == id)
            .firstOrNull;
      }
    });
  }

  void _onOptionSelected(int index) {
    _resetInactivityTimer();
    setState(() => _selectedOption = index);
  }

  void _checkAnswer() {
    _timer?.cancel();
    _inactivityTimer?.cancel();

    final isCorrect = _selectedOption == _currentQuestion.correctIndex;
    // Use schema fields with fallbacks for backward compatibility
    final primaryConcept = _getPrimaryConcept(_currentQuestion);
    final chapter = _getChapter(_currentQuestion);

    widget.tracker.recordAttempt(QuestionAttempt(
      questionId: _currentQuestion.id,
      topic: _currentQuestion.topic,
      coreConcept: _currentQuestion.coreConcept ?? _currentQuestion.topic,
      primaryConcept: primaryConcept,
      subject: _currentQuestion.subject,
      chapter: chapter,
      correct: isCorrect,
      timeSeconds: _elapsedSeconds,
      tapCount: _tapCount,
      hintsUsed: _hintsUsed,
      expectedTimeSeconds: _currentQuestion.estimatedSeconds ?? 60,
      timestamp: DateTime.now(),
      isRevision: widget.isRevisionMode,
    ));

    // Auto-add wrong answers to revision queue
    if (!isCorrect) {
      widget.revisionManager.autoAddWrongAnswer(
        questionId: _currentQuestion.id,
        topic: _currentQuestion.topic,
        coreConcept: _currentQuestion.coreConcept ?? _currentQuestion.topic,
      );
    }

    // Update revision result if in revision mode
    if (widget.isRevisionMode) {
      widget.revisionManager.recordReviewResult(
        _currentQuestion.id,
        isCorrect,
      );
    }

    setState(() {
      _showAnswer = true;
      // Auto-highlight after wrong answer
      if (!isCorrect) {
        _autoHighlightRelevant();
      }
    });

    // If in rescue mode, notify about answer
    if (_isRescueMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onRescueAnswered(isCorrect);
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _sessionQuestions.length - 1) {
      _navigateToQuestion(_currentIndex + 1);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _navigateToQuestion(_currentIndex - 1);
    }
  }

  // Smart Rescue Flow
  void _startRescueFlow() {
    final currentQ = _isRescueMode ? _originalQuestion! : _currentQuestion;
    final rescuePath = _rescueSystem.getRescuePath(currentQ);
    
    if (rescuePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rescue questions available for this topic.')),
      );
      return;
    }

    setState(() {
      _isRescueMode = true;
      _originalQuestion = _isRescueMode ? _originalQuestion : currentQ;
      _rescuePath = rescuePath;
      _rescueIndex = 0;
      _selectedOption = null;
      _showAnswer = false;
      _highlightedIds.clear();
    });

    _showRescueDialog(rescuePath.first);
  }

  void _showRescueDialog(RescueQuestion rescue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.flutter_dash, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            const Text('Let\'s build the foundation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You got the previous question wrong. Let\'s try a simpler one first:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rescue.question.text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${rescue.reason}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadRescueQuestion(rescue);
            },
            child: const Text('Try This Question'),
          ),
        ],
      ),
    );
  }

  void _loadRescueQuestion(RescueQuestion rescue) {
    _slideController.reset();
    setState(() {
      _currentIndex = _sessionQuestions.indexOf(rescue.question);
      if (_currentIndex == -1) {
        // Question not in list - add temporarily
        _sessionQuestions.add(rescue.question);
        _currentIndex = _sessionQuestions.length - 1;
      }
      _selectedOption = null;
      _showAnswer = false;
      _highlightedIds.clear();
    });
    _slideController.forward();
  }

  void _onRescueAnswered(bool wasCorrect) {
    if (wasCorrect) {
      if (_rescueIndex < _rescuePath.length - 1) {
        // More rescue questions to go
        setState(() {
          _rescueIndex++;
          _selectedOption = null;
          _showAnswer = false;
          _highlightedIds.clear();
        });
        _showRescueDialog(_rescuePath[_rescueIndex]);
      } else {
        // All rescue questions done - show completion
        _showRescueCompleteDialog();
      }
    } else {
      // Still wrong - retry same rescue or show try again
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep trying! Review the explanation and try again.')),
      );
    }
  }

  void _showRescueCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('Great progress!'),
          ],
        ),
        content: const Text(
          'You\'ve completed the rescue questions. Now let\'s retry the original question with your refreshed understanding.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _returnToOriginalQuestion();
            },
            child: const Text('Retry Original Question'),
          ),
        ],
      ),
    );
  }

  void _returnToOriginalQuestion() {
    _slideController.reset();
    final originalIndex = _sessionQuestions.indexOf(_originalQuestion!);
    setState(() {
      _isRescueMode = false;
      _currentIndex = originalIndex >= 0 ? originalIndex : 0;
      _selectedOption = null;
      _showAnswer = false;
      _highlightedIds.clear();
      _rescuePath = [];
      _rescueIndex = 0;
    });
    _slideController.forward();
  }

  void _navigateToQuestion(int index) {
    _slideController.reset();
    setState(() {
      _currentIndex = index;
      _selectedOption = null;
      _showAnswer = false;
      _highlightedIds.clear();
      _showHints = false;
      _lastTappedElement = null;
      _drawingEnabled = false;
      _activeTool = DrawingTool.none;
      _drawnElements = [];
      _autoHighlighted = false;
      _hintsUsed = 0;
      _tapCount = 0;
    });
    _slideController.forward();
    _startTimer();
    _resetInactivityTimer();
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenDiagram(
          question: _currentQuestion,
          highlightedIds: _highlightedIds,
          showValues: _showValues,
          showHints: _showHints,
          showLabels: _showLabels,
          onElementTap: _onElementTap,
          onValuesChanged: (v) => setState(() => _showValues = v),
          onHintsChanged: (v) => setState(() => _showHints = v),
          onLabelsChanged: (v) => setState(() => _showLabels = v),
        ),
      ),
    );
  }

  void _onRevealStep(RevealStep step) {
    _hintsUsed++;
    setState(() {
      if (step.highlightIds != null) {
        _highlightedIds.addAll(step.highlightIds!);
      }
      if (step.showHints == true) {
        _showHints = true;
      }
    });
  }

  void _practiceSimilar() {
    final similar = _currentQuestion.similarQuestionIds;
    if (similar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No similar questions available yet.')),
      );
      return;
    }
    final similarQuestions = _sessionQuestions
        .where((q) => similar.contains(q.id))
        .toList();
    if (similarQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Similar questions not found.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          questions: similarQuestions,
          tracker: widget.tracker,
          premiumState: widget.premiumState,
          revisionManager: widget.revisionManager,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Q${_currentIndex + 1} of ${_sessionQuestions.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              widget.practiceMode.displayName,
              style: TextStyle(
                fontSize: 11,
                color: widget.practiceMode == PracticeMode.mockExam
                    ? Colors.red.shade400
                    : widget.practiceMode == PracticeMode.revision
                        ? Colors.purple.shade400
                        : Colors.blue.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentIndex > 0 ? _prevQuestion : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentIndex < _sessionQuestions.length - 1
                ? _nextQuestion
                : null,
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isWide ? _buildWideLayout(theme) : _buildMobileLayout(theme),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final progress = (_currentIndex + 1) / _sessionQuestions.length;
    return Column(
      children: [
        Expanded(
          flex: 45,
          child: _buildDiagramSection(theme),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    '${_currentIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, _) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.blue.shade600,
                                  ),
                                  minHeight: 6,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${_sessionQuestions.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 55,
          child: _buildQuestionSection(),
        ),
      ],
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    final progress = (_currentIndex + 1) / _sessionQuestions.length;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildDiagramSection(theme)),
              VerticalDivider(width: 1, color: Colors.grey.shade300),
              Expanded(child: _buildQuestionSection()),
            ],
          ),
        ),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Q${_currentIndex + 1}/${_sessionQuestions.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                      minHeight: 4,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      children: [
        Expanded(
          child: QuestionPanel(
            question: _currentQuestion,
            selectedIndex: _selectedOption,
            showAnswer: _showAnswer,
            onOptionSelected: _onOptionSelected,
            onCheckAnswer: _checkAnswer,
            elapsedSeconds: _elapsedSeconds,
          ),
        ),
        if (_currentQuestion.revealSteps.isNotEmpty && !_showAnswer && _allowsRevealSteps)
          PremiumGate(
            tier: _tier,
            featureEnabled: PremiumFeatures.guideMe(_tier),
            featureName: 'Guide Me',
            child: RevealPanel(
              steps: _currentQuestion.revealSteps,
              onStepRevealed: _onRevealStep,
            ),
          ),
        // Practice similar + performance after answering
        if (_showAnswer) ...[
          _buildPostAnswerActions(),
        ],
      ],
    );
  }

  Widget _buildPostAnswerActions() {
    final insight =
        widget.tracker.getInsightForTopic(_currentQuestion.topic);
    final q = _currentQuestion;
    final wasCorrect = _selectedOption == q.correctIndex;
    final reviseCount = widget.tracker.getAreasNeedingPractice().length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Concept + Mistake + Importance summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: wasCorrect
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: wasCorrect
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Concept - only in Learner/Revision mode
                if (q.coreConcept != null && widget.practiceMode != PracticeMode.mockExam) ...[
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          q.coreConcept!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                // Common mistake - only in Learner mode
                if (q.commonMistake != null && !wasCorrect && _allowsConceptExplanation) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber,
                          size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          q.commonMistake!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                // Importance - only in Learner/Revision mode
                if ((q.frequentlyAsked || q.highWeightTopic) && widget.practiceMode != PracticeMode.mockExam)
                  Row(
                    children: [
                      Icon(Icons.star_outline,
                          size: 14, color: Colors.indigo.shade600),
                      const SizedBox(width: 6),
                      Text(
                        q.frequentlyAsked && q.highWeightTopic
                            ? 'Frequently asked & High weight in JEE'
                            : q.frequentlyAsked
                                ? 'Frequently asked in JEE'
                                : 'High weight topic in JEE',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mark for revision button
          SizedBox(
            width: double.infinity,
            child: ListenableBuilder(
              listenable: widget.revisionManager,
              builder: (context, _) {
                final isMarked = widget.revisionManager
                    .isMarkedForRevision(q.id);
                return OutlinedButton.icon(
                  onPressed: () {
                    widget.revisionManager.toggleRevision(
                      questionId: q.id,
                      topic: q.topic,
                      coreConcept: q.coreConcept ?? q.topic,
                    );
                  },
                  icon: Icon(
                    isMarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 16,
                    color: isMarked
                        ? Colors.purple.shade700
                        : Colors.purple.shade400,
                  ),
                  label: Text(
                    isMarked
                        ? 'Marked for Revision'
                        : 'Add to Revision',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple.shade700,
                    side: BorderSide(
                      color: isMarked
                          ? Colors.purple.shade400
                          : Colors.purple.shade200,
                    ),
                    backgroundColor: isMarked
                        ? Colors.purple.shade50
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Revision mode badge
          if (widget.isRevisionMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.deepPurple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.replay,
                      size: 16,
                      color: Colors.deepPurple.shade700),
                  const SizedBox(width: 6),
                  Text(
                    wasCorrect
                        ? 'Great! Interval increased. Next review later.'
                        : 'Needs more practice. Will appear again tomorrow.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Weak area insight (premium)
          if (insight != null && PremiumFeatures.weakAreaTracking(_tier)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_down,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Revision nudge
          if (reviseCount > 0) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: Colors.purple.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'You have $reviseCount topic${reviseCount > 1 ? 's' : ''} to revise',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Practice similar + next (automatic feel) - only in Learner/Revision mode
          if (widget.practiceMode != PracticeMode.mockExam) ...[
            if (q.similarQuestionIds.isNotEmpty &&
                PremiumFeatures.similarQuestions(_tier))
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _practiceSimilar,
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Practice 2 More Like This'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else if (!PremiumFeatures.similarQuestions(_tier))
              PremiumGate(
                tier: _tier,
                featureEnabled: false,
                featureName: 'Practice Similar',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Practice 2 More Like This'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
          // Smart Rescue - only in Learner mode for wrong answers
          if (!wasCorrect && _allowsHints) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _startRescueFlow,
                icon: const Icon(Icons.flutter_dash, size: 16),
                label: const Text('Smart Rescue: Build the foundation'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.purple.shade100,
                  foregroundColor: Colors.purple.shade800,
                ),
              ),
            ),
          ],
          if (_currentIndex < _sessionQuestions.length - 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Next Question'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagramSection(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Layer toggles + drawing tools + expand button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        LayerToggleBar(
                          showValues: _showValues,
                          showHints: _showHints,
                          showLabels: _showLabels,
                          onValuesChanged: (v) =>
                              setState(() => _showValues = v),
                          onHintsChanged: (v) =>
                              setState(() => _showHints = v),
                          onLabelsChanged: (v) =>
                              setState(() => _showLabels = v),
                        ),
                        const SizedBox(width: 8),
                        PremiumGate(
                          tier: _tier,
                          featureEnabled: PremiumFeatures.drawingTools(_tier),
                          featureName: 'Drawing Tools',
                          child: DrawingToolbar(
                            activeTool: _activeTool,
                            drawingEnabled: _drawingEnabled,
                            onToggleDrawing: () {
                              if (!PremiumFeatures.drawingTools(_tier)) return;
                              setState(() {
                                _drawingEnabled = !_drawingEnabled;
                                _activeTool = _drawingEnabled
                                    ? DrawingTool.line
                                    : DrawingTool.none;
                              });
                            },
                            onToolSelected: (tool) {
                              if (!PremiumFeatures.drawingTools(_tier)) return;
                              setState(() => _activeTool = tool);
                            },
                            onUndo: () {
                              if (_drawnElements.isNotEmpty) {
                                setState(() {
                                  _drawnElements = _drawnElements.sublist(
                                      0, _drawnElements.length - 1);
                                });
                              }
                            },
                            onClearAll: () =>
                                setState(() => _drawnElements = []),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _openFullscreen,
                  tooltip: 'Fullscreen',
                ),
              ],
            ),
          ),

          // Diagram title
          if (_currentQuestion.diagram.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _currentQuestion.diagram.title!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          // Auto-highlight hint
          if (_autoHighlighted && !_showAnswer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 14, color: Colors.purple.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Auto-highlighted key elements to help you get started',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Diagram canvas + drawing overlay
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  DiagramCanvas(
                    diagram: _currentQuestion.diagram,
                    highlightedIds: _highlightedIds,
                    showValues: _showValues,
                    showHints: _showHints,
                    showLabels: _showLabels,
                    onElementTap:
                        _drawingEnabled ? null : _onElementTap,
                  ),
                  DrawingOverlay(
                    enabled: _drawingEnabled,
                    activeTool: _activeTool,
                    drawnElements: _drawnElements,
                    onElementsChanged: (elements) =>
                        setState(() => _drawnElements = elements),
                  ),
                ],
              ),
            ),
          ),

          // Insight panel (premium)
          if (_lastTappedElement != null &&
              _lastTappedElement!.insight != null &&
              PremiumFeatures.tapInsight(_tier))
            InsightPanel(
              element: _lastTappedElement!,
              onDismiss: () => setState(() => _lastTappedElement = null),
            ),

          // Highlighted elements info
          if (_highlightedIds.isNotEmpty &&
              _lastTappedElement?.insight == null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.touch_app,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Selected: ${_highlightedIds.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _highlightedIds.clear();
                      _lastTappedElement = null;
                    }),
                    child: Icon(Icons.clear,
                        size: 16, color: Colors.amber.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
