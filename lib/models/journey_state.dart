import 'question_attempt.dart';

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

  factory StudentJourneyState.fromJson(Map<String, dynamic> json) {
    return StudentJourneyState(
      journeyId: json['journeyId'] as String,
      studentId: json['studentId'] as String,
      currentLevelIndex: json['currentLevelIndex'] as int? ?? 0,
      levelStates: (json['levelStates'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.parse(key),
              _parseLevelState(value as String),
            ),
          ) ??
          {},
      attempts: (json['attempts'] as List<dynamic>?)
          ?.map((e) => QuestionAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      completionDate: json['completionDate'] != null 
          ? DateTime.parse(json['completionDate'] as String) 
          : null,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'studentId': studentId,
      'currentLevelIndex': currentLevelIndex,
      'levelStates': levelStates.map(
        (key, value) => MapEntry(key.toString(), value.name),
      ),
      'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
    };
  }

  static LevelState _parseLevelState(String value) {
    switch (value) {
      case 'notStarted':
        return LevelState.notStarted;
      case 'inProgress':
        return LevelState.inProgress;
      case 'needsPractice':
        return LevelState.needsPractice;
      case 'mastered':
        return LevelState.mastered;
      default:
        return LevelState.notStarted;
    }
  }

  void addAttempt(QuestionAttempt attempt) {
    attempts.add(attempt);
    startDate ??= DateTime.now();
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
  notStarted,
  inProgress,
  needsPractice,
  mastered,
}
