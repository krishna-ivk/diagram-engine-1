import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/question_data.dart';
import '../models/question_attempt.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);
  
  final http.Client _client;
  
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  
  // Generic request method
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          message: 'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('HTTP error occurred');
    } on FormatException {
      throw ApiException(message: 'Invalid response format');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
  
  // Student endpoints
  Future<Map<String, dynamic>> createStudent({
    required String subscriptionLevel,
    required String targetExam,
    required String classLevel,
  }) async {
    return await _request('POST', '/api/v1/students', body: {
      'subscription_level': subscriptionLevel,
      'target_exam': targetExam,
      'class_level': classLevel,
    });
  }
  
  Future<Map<String, dynamic>> getStudent(String studentId) async {
    return await _request('GET', '/api/v1/students/$studentId');
  }
  
  // Adaptive learning endpoints
  Future<Map<String, dynamic>> getNextQuestion({
    required String studentId,
    required String topicId,
    required List<Map<String, dynamic>> recentAttempts,
    String? requestedDifficulty,
    String sessionType = 'practice',
  }) async {
    return await _request('POST', '/api/v1/adaptive/next-question', body: {
      'student_id': studentId,
      'topic_id': topicId,
      'recent_attempts': recentAttempts,
      'requested_difficulty': requestedDifficulty,
      'session_type': sessionType,
    });
  }
  
  Future<Map<String, dynamic>> recordAttempt({
    required String studentId,
    required String questionId,
    required int selectedOptionIndex,
    required bool isCorrect,
    required String confidenceLevel,
    required int timeSpentSeconds,
    String? mistakePattern,
    String? misconceptionDetected,
    String? topicId,
    String? conceptId,
  }) async {
    return await _request('POST', '/api/v1/attempts', body: {
      'student_id': studentId,
      'question_id': questionId,
      'selected_option_index': selectedOptionIndex,
      'is_correct': isCorrect,
      'confidence_level': confidenceLevel,
      'time_spent_seconds': timeSpentSeconds,
      'mistake_pattern': mistakePattern,
      'misconception_detected': misconceptionDetected,
      'topic_id': topicId,
      'concept_id': conceptId,
    });
  }
  
  // Mastery endpoints
  Future<Map<String, dynamic>> getMasteryProfile(String studentId) async {
    return await _request('GET', '/api/v1/students/$studentId/mastery');
  }
  
  Future<List<Map<String, dynamic>>> getWeakAreas(String studentId) async {
    final response = await _request('GET', '/api/v1/analytics/weak-areas/$studentId');
    return (response['weak_areas'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  
  // Mock test endpoints
  Future<Map<String, dynamic>> generateMockTest({
    required String studentId,
    int durationMinutes = 180,
    List<String>? topics,
    Map<String, int>? difficultyDistribution,
  }) async {
    return await _request('POST', '/api/v1/mock-tests/generate', body: {
      'student_id': studentId,
      'duration_minutes': durationMinutes,
      'topics': topics,
      'difficulty_distribution': difficultyDistribution,
    });
  }
  
  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    return await _request('GET', '/api/v1/health');
  }
  
  void dispose() {
    _client.close();
  }
}

// Exception classes
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  
  ApiException({
    required this.message,
    this.statusCode,
    this.body,
  });
  
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}