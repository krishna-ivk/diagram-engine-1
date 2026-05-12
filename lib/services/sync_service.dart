import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning_service.dart';
import 'connectivity_service.dart';
import '../models/question_attempt.dart';

class SyncService {
  final LearningService _learningService;
  final ConnectivityService _connectivityService;
  final SharedPreferences _prefs;
  
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  
  SyncService({
    required LearningService learningService,
    required ConnectivityService connectivityService,
    required SharedPreferences prefs,
  }) : _learningService = learningService,
       _connectivityService = connectivityService,
       _prefs = prefs {
    
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen(_onConnectivityChanged);
    
    // Start periodic sync
    _startPeriodicSync();
  }
  
  void _onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      // Trigger immediate sync when coming back online
      _triggerSync();
    }
  }
  
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      if (_connectivityService.isOnline) {
        _triggerSync();
      }
    });
  }
  
  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      await _syncPendingAttempts();
      await _syncMasteryData();
      await _cleanupOldLocalData();
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _syncPendingAttempts() async {
    final pendingAttempts = await _getPendingAttempts();
    
    if (pendingAttempts.isEmpty) return;
    
    print('Syncing ${pendingAttempts.length} pending attempts...');
    
    for (final attempt in pendingAttempts) {
      try {
        await _learningService.recordAttempt(attempt);
        await _markAttemptAsSynced(attempt.id);
      } catch (e) {
        print('Failed to sync attempt ${attempt.id}: $e');
        // Continue with other attempts
      }
    }
  }
  
  Future<List<QuestionAttempt>> _getPendingAttempts() async {
    final attemptsJson = _prefs.getString('pending_attempts') ?? '[]';
    final attemptsList = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    return attemptsList
        .map((json) => QuestionAttempt.fromJson(json))
        .where((attempt) => !attempt.isSynced)
        .toList();
  }
  
  Future<void> _markAttemptAsSynced(String attemptId) async {
    final attemptsJson = _prefs.getString('pending_attempts') ?? '[]';
    final attemptsList = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    for (final attempt in attemptsList) {
      if (attempt['id'] == attemptId) {
        attempt['is_synced'] = true;
        attempt['synced_at'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    await _prefs.setString('pending_attempts', jsonEncode(attemptsList));
  }
  
  Future<void> _syncMasteryData() async {
    try {
      // Get latest mastery data from server
      final masteryProfile = await _learningService.getMasteryProfile();
      
      // Cache locally for offline access
      await _prefs.setString(
        'cached_mastery_profile',
        jsonEncode(masteryProfile),
      );
      
      // Update cache timestamp
      await _prefs.setString(
        'mastery_cache_timestamp',
        DateTime.now().toIso8601String(),
      );
      
    } catch (e) {
      print('Failed to sync mastery data: $e');
    }
  }
  
  Future<void> _cleanupOldLocalData() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: 30));
    
    // Clean up old synced attempts
    final attemptsJson = _prefs.getString('pending_attempts') ?? '[]';
    final attemptsList = List<Map<String, dynamic>>.from(jsonDecode(attemptsJson));
    
    final filteredAttempts = attemptsList.where((attempt) {
      if (!attempt['is_synced']) return true; // Keep unsynced attempts
      
      final attemptDate = DateTime.parse(attempt['created_at']);
      return attemptDate.isAfter(cutoffDate);
    }).toList();
    
    await _prefs.setString('pending_attempts', jsonEncode(filteredAttempts));
    
    // Clean up old cached data
    final cacheTimestamp = _prefs.getString('mastery_cache_timestamp');
    if (cacheTimestamp != null) {
      final cacheDate = DateTime.parse(cacheTimestamp);
      if (cacheDate.isBefore(cutoffDate)) {
        await _prefs.remove('cached_mastery_profile');
        await _prefs.remove('mastery_cache_timestamp');
      }
    }
  }
  
  // Public methods for manual sync
  Future<void> forceSyncNow() async {
    await _triggerSync();
  }
  
  Future<bool> hasPendingSync() async {
    final pendingAttempts = await _getPendingAttempts();
    return pendingAttempts.isNotEmpty;
  }
  
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingAttempts = await _getPendingAttempts();
    final lastSyncTime = _prefs.getString('last_successful_sync');
    
    return {
      'has_pending_sync': pendingAttempts.isNotEmpty,
      'pending_attempts_count': pendingAttempts.length,
      'last_successful_sync': lastSyncTime,
      'is_online': _connectivityService.isOnline,
      'is_syncing': _isSyncing,
    };
  }
  
  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}