import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'lib/services/api_client.dart';
import 'lib/services/learning_service.dart';
import 'lib/services/connectivity_service.dart';
import 'lib/services/sync_service.dart';
import 'lib/models/question_data.dart';
import 'lib/models/question_attempt.dart';

import 'integration_test.mocks.dart';

@GenerateMocks([http.Client, SharedPreferences])
void main() {
  group('End-to-End Integration Tests', () {
    late MockClient mockHttpClient;
    late MockSharedPreferences mockPrefs;
    late ApiClient apiClient;
    late LearningService learningService;
    late ConnectivityService connectivityService;
    late SyncService syncService;

    setUp(() async {
      mockHttpClient = MockClient();
      mockPrefs = MockSharedPreferences();
      apiClient = ApiClient(client: mockHttpClient);
      learningService = LearningService(
        apiClient: apiClient,
        prefs: mockPrefs,
      );
      connectivityService = ConnectivityService();
      syncService = SyncService(
        learningService: learningService,
        connectivityService: connectivityService,
        prefs: mockPrefs,
      );

      // Setup default mock responses
      when(mockPrefs.getString('student_id')).thenReturn('test_student_123');
      when(mockPrefs.getString('local_attempts')).thenReturn('[]');
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
    });

    tearDown(() {
      learningService.dispose();
      syncService.dispose();
    });

    group('Student Management', () {
      test('should create new student when none exists', () async {
        // Arrange
        when(mockPrefs.getString('student_id')).thenReturn(null);
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'id': 'new_student_456',
                  'created_at': '2024-01-01T00:00:00Z',
                  'subscription_level': 'free',
                  'target_exam': 'jee',
                  'class_level': 'Class 11'
                }),
                200));

        // Act
        final student = await learningService.getOrCreateStudent();

        // Assert
        expect(student.id, equals('new_student_456'));
        verify(mockPrefs.setString('student_id', 'new_student_456')).called(1);
      });

      test('should retrieve existing student', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'id': 'test_student_123',
                  'created_at': '2024-01-01T00:00:00Z',
                  'subscription_level': 'free',
                  'target_exam': 'jee',
                  'class_level': 'Class 11'
                }),
                200));

        // Act
        final student = await learningService.getOrCreateStudent();

        // Assert
        expect(student.id, equals('test_student_123'));
      });
    });

    group('Adaptive Question Selection', () {
      test('should get next adaptive question from API', () async {
        // Arrange
        final mockQuestionResponse = {
          'question': {
            'id': 'adaptive_question_001',
            'text': 'What is the central angle of a regular hexagon?',
            'options': ['45°', '60°', '90°', '120°'],
            'correct_index': 1,
            'explanation': 'Central angle = 360° ÷ 6 = 60°',
            'subject': 'Mathematics',
            'topic': 'Central Angle of Regular Polygon',
            'primary_concept': 'central_angle_regular_polygon',
            'difficulty': 'medium',
            'question_type': 'mcq',
            'estimated_seconds': 45,
            'frequently_asked': true,
            'high_weight_topic': false,
            'solution_steps': ['Divide 360° by the number of sides'],
            'why_wrong_explanations': {0: '45° is for octagon'},
            'formulae_used': ['central_angle = 360° / n']
          }
        };

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode(mockQuestionResponse),
                200));

        // Act
        final question = await learningService.getNextAdaptiveQuestion(
          topicId: 'math.geometry.central_angle_regular_polygon',
        );

        // Assert
        expect(question.id, equals('adaptive_question_001'));
        expect(question.text, contains('central angle of a regular hexagon'));
        expect(question.options, hasLength(4));
        expect(question.correctIndex, equals(1));
      });

      test('should fallback to local question when API fails', () async {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        // Act
        final question = await learningService.getNextAdaptiveQuestion(
          topicId: 'math.geometry.central_angle_regular_polygon',
        );

        // Assert
        expect(question.id, equals('emergency_fallback'));
        expect(question.text, contains('regular polygon has 6 equal sides'));
      });
    });

    group('Attempt Recording with Offline Support', () {
      test('should record attempt online successfully', () async {
        // Arrange
        connectivityService.setConnectivityStatus(true);
        
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'id': 'attempt_123',
                  'mastery_updated': true,
                  'weak_areas_identified': []
                }),
                200));

        final attempt = QuestionAttempt(
          questionId: 'test_question_001',
          confidenceLevel: ConfidenceLevel.somewhatSure,
          isCorrect: true,
          timeSpentSeconds: 45,
          timestamp: DateTime.now(),
          levelIndex: 0,
        );

        // Act
        await learningService.recordAttempt(attempt);

        // Assert
        verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            contains('test_question_001'),
            named: 'body'
          ),
        )).called(1);
      });

      test('should store attempt locally when offline', () async {
        // Arrange
        connectivityService.setConnectivityStatus(false);
        
        final attempt = QuestionAttempt(
          questionId: 'offline_attempt_001',
          confidenceLevel: ConfidenceLevel.notSure,
          isCorrect: false,
          timeSpentSeconds: 30,
          timestamp: DateTime.now(),
          levelIndex: 0,
        );

        // Act
        await learningService.recordAttempt(attempt);

        // Assert
        verify(mockPrefs.setString(
          'local_attempts',
          argThat(contains('offline_attempt_001')),
        )).called(1);
        
        // Should not attempt API call when offline
        verifyNever(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')));
      });
    });

    group('Mastery Profile', () {
      test('should get mastery profile from API', () async {
        // Arrange
        final mockMasteryResponse = {
          'student_id': 'test_student_123',
          'concept_mastery': [
            {
              'concept_id': 'central_angle_regular_polygon',
              'mastery_score': 0.75,
              'total_attempts': 20,
              'correct_attempts': 15,
              'recent_accuracy': 0.8,
              'trend': 'improving'
            }
          ],
          'overall_mastery_score': 0.75,
          'strong_areas': ['central_angle_regular_polygon'],
          'weak_areas': [],
          'recommendations': ['Continue practicing to reach mastery level.']
        };

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                jsonEncode(mockMasteryResponse),
                200));

        // Act
        final mastery = await learningService.getMasteryProfile();

        // Assert
        expect(mastery['overall_mastery_score'], equals(0.75));
        expect(mastery['strong_areas'], contains('central_angle_regular_polygon'));
        expect(mastery['recommendations'], isNotEmpty);
      });

      test('should return local mastery data when API fails', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('Network error'));
        
        when(mockPrefs.getString('local_attempts')).thenReturn(jsonEncode([
          {
            'question_id': 'test_001',
            'is_correct': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'question_id': 'test_002',
            'is_correct': false,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]));

        // Act
        final mastery = await learningService.getMasteryProfile();

        // Assert
        expect(mastery['overall_mastery_score'], equals(0.5)); // 1 correct out of 2
        expect(mastery['student_id'], equals('test_student_123'));
      });
    });

    group('Mock Test Generation', () {
      test('should generate personalized mock test', () async {
        // Arrange
        final mockTestResponse = {
          'id': 'mock_test_001',
          'student_id': 'test_student_123',
          'questions': [
            {
              'question_id': 'test_q_001',
              'question_data': {
                'id': 'test_q_001',
                'text': 'Test question',
                'options': ['A', 'B', 'C', 'D'],
                'correct_index': 0
              },
              'marks': 4,
              'time_limit_seconds': 60
            }
          ],
          'total_marks': 100,
          'duration_minutes': 180,
          'created_at': '2024-01-01T00:00:00Z',
          'instructions': ['Follow all instructions carefully']
        };

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode(mockTestResponse),
                200));

        // Act
        final mockTest = await learningService.generateMockTest(
          durationMinutes: 180,
          topics: ['math.geometry.central_angle_regular_polygon'],
        );

        // Assert
        expect(mockTest['id'], equals('mock_test_001'));
        expect(mockTest['total_marks'], equals(100));
        expect(mockTest['questions'], isNotEmpty);
      });
    });

    group('Sync Service', () {
      test('should sync pending attempts when online', () async {
        // Arrange
        connectivityService.setConnectivityStatus(true);
        
        final pendingAttempts = [
          {
            'id': 'pending_001',
            'question_id': 'test_q_001',
            'is_correct': true,
            'is_synced': false,
            'created_at': DateTime.now().toIso8601String(),
          }
        ];

        when(mockPrefs.getString('pending_attempts')).thenReturn(jsonEncode(pendingAttempts));
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode({'id': 'synced_attempt_001'}),
                200));

        // Act
        await syncService.forceSyncNow();

        // Assert
        verify(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .called(1);
      });

      test('should report sync status correctly', () async {
        // Arrange
        final pendingAttempts = [
          {
            'id': 'pending_001',
            'question_id': 'test_q_001',
            'is_correct': true,
            'is_synced': false,
            'created_at': DateTime.now().toIso8601String(),
          }
        ];

        when(mockPrefs.getString('pending_attempts')).thenReturn(jsonEncode(pendingAttempts));

        // Act
        final status = await syncService.getSyncStatus();

        // Assert
        expect(status['has_pending_sync'], isTrue);
        expect(status['pending_attempts_count'], equals(1));
        expect(status['is_online'], isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle API errors gracefully', () async {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('Server error', 500));

        // Act & Assert
        expect(
          () => learningService.getNextAdaptiveQuestion(topicId: 'test_topic'),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('No internet connection'));

        // Act
        final mastery = await learningService.getMasteryProfile();

        // Assert
        expect(mastery, isA<Map<String, dynamic>>());
        expect(mastery['overall_mastery_score'], isA<double>());
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid question loading', (WidgetTester tester) async {
        // Arrange
        final mockQuestionResponse = {
          'question': {
            'id': 'rapid_question_001',
            'text': 'Rapid loading test question',
            'options': ['A', 'B', 'C', 'D'],
            'correct_index': 0,
            'subject': 'Mathematics',
            'topic': 'Test',
            'primary_concept': 'test',
            'difficulty': 'easy',
            'question_type': 'mcq',
            'estimated_seconds': 30,
          }
        };

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                jsonEncode(mockQuestionResponse),
                200));

        final stopwatch = Stopwatch()..start();

        // Act
        for (int i = 0; i < 10; i++) {
          await learningService.getNextAdaptiveQuestion(
            topicId: 'test_topic',
          );
        }

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      });
    });
  });
}