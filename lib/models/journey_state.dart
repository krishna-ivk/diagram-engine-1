import 'package:json_annotation/json_annotation.dart';
import 'question_attempt.dart';

part 'journey_state.g.dart';

@JsonSerializable()
class StudentJourneyState {
  final String journeyId;
  final String studentId;
  int currentLevelIndex;
  final Map<int, LevelState> levelStates;
  final List<QuestionAttempt> attempts;
  bool isCompleted;
  DateTime? completionDate;
  DateTime? startDate;

  StudentJourneyState({
    required this.journeyId,
    required this.studentId,
    this.currentLevelIndex = 0,
    Map<int, LevelState>? levelStates,
    List<QuestionAttempt>? attempts,
    this.isCompleted = false,
    this.completionDate,
    this.startDate,
  }) : levelStates = levelStates ?? {},
       attempts = attempts ?? [];

  factory StudentJourneyState.fromJson(Map<String, dynamic> json) =>
      _$StudentJourneyStateFromJson(json);

  Map<String, dynamic> toJson() => _$StudentJourneyStateToJson(this);

  void addAttempt(QuestionAttempt attempt) {
    attempts.add(attempt);
    if (startDate == null) {
      startDate = DateTime.now();
    }
  }

  List<QuestionAttempt> attemptsForLevel(int levelIndex) {
    return attempts.where((a) => a.levelIndex == levelIndex).toList();
  }

  List<QuestionAttempt> recentAttemptsForLevel(int levelIndex, {int count = 5}) {
    final levelAttempts = attemptsForLevel(levelIndex);
    return levelAttempts.reversed.take(count).toList().reversed.toList();
  }

  List<QuestionAttempt> get allAttempts => List.unmodifiable(attempts);

  void markLevelCompleted(int levelIndex) {
    levelStates[levelIndex] = LevelState.mastered;
  }

  void markLevelNeedsPractice(int levelIndex) {
    levelStates[levelIndex] = LevelState.needsPractice;
  }

  void markLevelInProgress(int levelIndex) {
    levelStates[levelIndex] = LevelState.inProgress;
  }

  LevelState getLevelState(int levelIndex) {
    return levelStates[levelIndex] ?? LevelState.notStarted;
  }

  double getOverallAccuracy() {
    if (attempts.isEmpty) return 0.0;
    final correct = attempts.where((a) => a.isCorrect).length;
    return correct / attempts.length;
  }

  Duration getTotalTimeSpent() {
    final totalSeconds = attempts.fold<int>(
      0, 
      (sum, attempt) => sum + attempt.timeSpentSeconds
    );
    return Duration(seconds: totalSeconds);
  }

  Map<String, dynamic> toProgressMap() {
    return {
      'journeyId': journeyId,
      'studentId': studentId,
      'currentLevel': currentLevelIndex,
      'totalLevels': levelStates.length,
      'completedLevels': levelStates.values.where((s) => s == LevelState.mastered).length,
      'accuracy': getOverallAccuracy(),
      'timeSpent': getTotalTimeSpent().inMinutes,
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
    };
  }
}

enum LevelState {
  @JsonValue('notStarted')
  notStarted,
  
  @JsonValue('inProgress') 
  inProgress,
  
  @JsonValue('needsPractice')
  needsPractice,
  
  @JsonValue('mastered')
  mastered,
}