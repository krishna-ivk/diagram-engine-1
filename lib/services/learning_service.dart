import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/question_data.dart';
import '../models/question_attempt.dart';
import '../models/student_profile_simple.dart';

class LearningService {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;
  final List<QuestionAttempt> _pendingAttempts = [];
  bool _isOnline = true;
  Timer? _syncTimer;
  
  LearningService({
    required ApiClient apiClient,
    required SharedPreferences prefs,
  }) : _apiClient = apiClient,
       _prefs = prefs {
    _startPeriodicSync();
  }
  
  // Student management
  Future<StudentProfile> getOrCreateStudent() async {
    final studentId = _prefs.getString('student_id');
    
    if (studentId != null) {
      try {
        final response = await _apiClient.getStudent(studentId);
        return StudentProfile.fromJson(response);
      } catch (e) {
        // Student might not exist on server, create new one
        return await _createNewStudent();
      }
    } else {
      return await _createNewStudent();
    }
  }
  
  Future<StudentProfile> _createNewStudent() async {
    final response = await _apiClient.createStudent(
      subscriptionLevel: 'free',
      targetExam: 'jee',
      classLevel: 'Class 11',
    );
    
    final student = StudentProfile.fromJson(response);
    await _prefs.setString('student_id', student.id);
    return student;
  }
  
  // Adaptive question selection
  Future<QuestionData> getNextAdaptiveQuestion({
    required String topicId,
    String? requestedDifficulty,
    String sessionType = 'practice',
  }) async {
    final studentId = _prefs.getString('student_id') ?? '';
    final recentAttempts = await _getRecentAttempts(topicId);
    
    try {
      final response = await _apiClient.getNextQuestion(
        studentId: studentId,
        topicId: topicId,
        recentAttempts: recentAttempts.map((a) => a.toJson()).toList(),
        requestedDifficulty: requestedDifficulty,
        sessionType: sessionType,
      );
      
      return QuestionData.fromJson(response['question']);
    } catch (e) {
      // Fallback to local question selection
      return await _getFallbackQuestion(topicId);
    }
  }
  
  Future<QuestionData> _getFallbackQuestion(String topicId) async {
    // Load from local content as fallback
    // This would integrate with your existing TopicContentLoader
    final questions = await TopicContentLoader.loadQuestionsByIds([
      'fundamental_central_angle_square_001',
      'fundamental_central_angle_triangle_002',
    ]);
    
    return questions.isNotEmpty ? questions.first : _createEmergencyFallback();
  }
  
  QuestionData _createEmergencyFallback() {
    return QuestionData(
      id: 'emergency_fallback',
      text: 'A regular polygon has 6 equal sides. What is each central angle?',
      diagram: DiagramData(
        id: 'emergency_diagram',
        type: DiagramType.geometry,
        elements: [],
      ),
      options: const ['45°', '60°', '90°', '120°'],
      correctIndex: 1,
      explanation: 'Central angle = 360° ÷ number of sides = 360° ÷ 6 = 60°',
      subject: 'Mathematics',
      topic: 'Central Angle of Regular Polygon',
      primaryConcept: 'central_angle_regular_polygon',
      difficulty: Difficulty.medium,
      estimatedSeconds: 45,
    );
  }
  
  // Attempt recording with offline support
  Future<void> recordAttempt(QuestionAttempt attempt) async {
    // Store locally immediately
    await _saveAttemptLocally(attempt);
    _pendingAttempts.add(attempt);
    
    // Try to sync immediately if online
    if (_isOnline) {
      await _syncAttempt(attempt);
    }
  }
  
  Future<void> _saveAttemptLocally(QuestionAttempt attempt) async {
    final attemptsJson = _prefs.getString('local_attempts') ?? '[]';
    final attempts = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    attempts.add(attempt.toJson());
    await _prefs.setString('local_attempts', jsonEncode(attempts));
  }
  
  Future<void> _syncAttempt(QuestionAttempt attempt) async {
    try {
      final studentId = _prefs.getString('student_id') ?? '';
      
      await _apiClient.recordAttempt(
        studentId: studentId,
        questionId: attempt.questionId,
        selectedOptionIndex: 0, // This would come from the attempt
        isCorrect: attempt.isCorrect,
        confidenceLevel: attempt.confidenceLevel.name,
        timeSpentSeconds: attempt.timeSpentSeconds,
        topicId: 'math.geometry.central_angle_regular_polygon', // Extract from attempt
        conceptId: 'central_angle_regular_polygon', // Extract from attempt
      );
      
      // Remove from pending after successful sync
      _pendingAttempts.remove(attempt);
      await _markAttemptSynced(attempt);
      
    } catch (e) {
      // Keep in pending queue for later retry
      print('Failed to sync attempt: $e');
    }
  }
  
  Future<void> _markAttemptSynced(QuestionAttempt attempt) async {
    final attemptsJson = _prefs.getString('local_attempts') ?? '[]';
    final attempts = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    // Remove synced attempt
    attempts.removeWhere((a) => a['question_id'] == attempt.questionId);
    await _prefs.setString('local_attempts', jsonEncode(attempts));
  }
  
  // Periodic sync for offline attempts
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (_isOnline && _pendingAttempts.isNotEmpty) {
        _syncPendingAttempts();
      }
    });
  }
  
  Future<void> _syncPendingAttempts() async {
    final attemptsToSync = List<QuestionAttempt>.from(_pendingAttempts);
    
    for (final attempt in attemptsToSync) {
      await _syncAttempt(attempt);
    }
  }
  
  // Get recent attempts for adaptive learning
  Future<List<QuestionAttempt>> _getRecentAttempts(String topicId) async {
    final attemptsJson = _prefs.getString('local_attempts') ?? '[]';
    final attempts = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    // Filter by topic and get last 10 attempts
    final topicAttempts = attempts
        .where((a) => a['topic_id']?.toString().contains(topicId) ?? false)
        .take(10)
        .map((a) => QuestionAttempt.fromJson(a))
        .toList();
    
    return topicAttempts;
  }
  
  // Mastery and analytics
  Future<Map<String, dynamic>> getMasteryProfile() async {
    final studentId = _prefs.getString('student_id') ?? '';
    
    try {
      return await _apiClient.getMasteryProfile(studentId);
    } catch (e) {
      // Return local mastery data as fallback
      return await _getLocalMasteryProfile();
    }
  }
  
  Future<Map<String, dynamic>> _getLocalMasteryProfile() async {
    final attemptsJson = _prefs.getString('local_attempts') ?? '[]';
    final attempts = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    // Calculate basic mastery from local attempts
    final totalAttempts = attempts.length;
    final correctAttempts = attempts.where((a) => a['is_correct'] == true).length;
    final overallScore = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;
    
    return {
      'student_id': _prefs.getString('student_id') ?? '',
      'concept_mastery': [],
      'overall_mastery_score': overallScore,
      'strong_areas': [],
      'weak_areas': [],
      'recommendations': ['Continue practicing to improve your skills.']
    };
  }
  
  Future<List<Map<String, dynamic>>> getWeakAreas() async {
    final studentId = _prefs.getString('student_id') ?? '';
    
    try {
      return await _apiClient.getWeakAreas(studentId);
    } catch (e) {
      return [];
    }
  }
  
  // Mock test generation
  Future<Map<String, dynamic>> generateMockTest({
    int durationMinutes = 180,
    List<String>? topics,
    Map<String, int>? difficultyDistribution,
  }) async {
    final studentId = _prefs.getString('student_id') ?? '';
    
    try {
      return await _apiClient.generateMockTest(
        studentId: studentId,
        durationMinutes: durationMinutes,
        topics: topics,
        difficultyDistribution: difficultyDistribution,
      );
    } catch (e) {
      // Return fallback mock test
      return _createFallbackMockTest();
    }
  }
  
  Map<String, dynamic> _createFallbackMockTest() {
    return {
      'id': 'fallback_mock_test',
      'student_id': _prefs.getString('student_id') ?? '',
      'questions': [],
      'total_marks': 100,
      'duration_minutes': 180,
      'created_at': DateTime.now().toIso8601String(),
      'instructions': [
        'This is a fallback test due to connectivity issues.',
        'Please check your internet connection.',
      ]
    };
  }
  
  // Connectivity management
  void setConnectivityStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline && _pendingAttempts.isNotEmpty) {
      _syncPendingAttempts();
    }
  }
  
  // Cleanup
  void dispose() {
    _syncTimer?.cancel();
    _apiClient.dispose();
  }
}