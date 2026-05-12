import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  bool _isOnline = true;
  Timer? _debounceTimer;
  
  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;
  
  void initialize() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Check initial connectivity
    _checkConnectivity();
  }
  
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // Debounce rapid connectivity changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _checkConnectivity();
    });
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
      }
    } catch (e) {
      _isOnline = false;
      _connectivityController.add(false);
    }
  }
  
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    _debounceTimer?.cancel();
    _connectivityController.close();
  }
}