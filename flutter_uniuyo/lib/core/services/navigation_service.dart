import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'mapbox_directions_service.dart';

/// Navigation state enum
enum NavigationState {
  idle,
  preparing,
  navigating,
  rerouting,
  arrived,
  error,
}

/// Real-time navigation service with GPS tracking, voice guidance, and rerouting
class NavigationService extends ChangeNotifier {
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Services
  final FlutterTts _tts = FlutterTts();
  final MapboxDirectionsService _directionsService = MapboxDirectionsService();
  StreamSubscription<Position>? _positionSubscription;

  // Navigation state
  NavigationState _state = NavigationState.idle;
  NavigationState get state => _state;

  // Current position
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Route data
  DirectionsResponse? _route;
  DirectionsResponse? get route => _route;

  List<RouteStep> _steps = [];
  List<RouteStep> get steps => _steps;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  RouteStep? get currentStep =>
      _currentStepIndex < _steps.length ? _steps[_currentStepIndex] : null;

  RouteStep? get nextStep =>
      _currentStepIndex + 1 < _steps.length ? _steps[_currentStepIndex + 1] : null;

  // Origin and destination
  List<double>? _origin; // [lng, lat]
  List<double>? _destination; // [lng, lat]
  String? _originName;
  String? _destinationName;
  String? get originName => _originName;
  String? get destinationName => _destinationName;

  // Progress tracking
  double _distanceRemaining = 0; // meters
  double get distanceRemaining => _distanceRemaining;

  double _durationRemaining = 0; // seconds
  double get durationRemaining => _durationRemaining;

  double _distanceToNextStep = 0; // meters to next turn
  double get distanceToNextStep => _distanceToNextStep;

  double _totalDistance = 0;
  double get totalDistance => _totalDistance;

  double _distanceTraveled = 0;
  double get distanceTraveled => _distanceTraveled;

  // Route coordinates for deviation check
  List<List<double>> _routeCoordinates = [];

  // Settings
  bool _voiceEnabled = true;
  bool get voiceEnabled => _voiceEnabled;

  double _deviationThreshold = 25.0; // meters off route before rerouting
  int _rerouteCount = 0;
  static const int _maxReroutes = 5;

  // Callbacks
  Function(Position)? onPositionUpdate;
  Function(int stepIndex)? onStepChange;
  Function()? onArrival;
  Function(String message)? onRerouting;
  Function(String error)? onError;

  /// Initialize TTS engine
  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Set TTS completion handler
    _tts.setCompletionHandler(() {
      debugPrint('NavigationService: TTS completed');
    });
  }

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Location services are disabled. Please enable GPS.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError?.call('Location permission denied. Navigation requires GPS access.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      onError?.call('Location permission permanently denied. Please enable in Settings.');
      return false;
    }

    return true;
  }

  /// Start navigation with a pre-calculated route
  Future<bool> startNavigation({
    required DirectionsResponse route,
    required List<double> origin,
    required List<double> destination,
    required String originName,
    required String destinationName,
  }) async {
    try {
      _state = NavigationState.preparing;
      notifyListeners();

      // Request permissions
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _state = NavigationState.error;
        notifyListeners();
        return false;
      }

      // Store route data
      _route = route;
      _origin = origin;
      _destination = destination;
      _originName = originName;
      _destinationName = destinationName;

      // Extract steps from route
      _steps = route.routes.first.legs.first.steps;
      _currentStepIndex = 0;

      // Store route coordinates for deviation checking
      _routeCoordinates = route.routes.first.coordinates;

      // Initialize progress
      _totalDistance = route.distance;
      _distanceRemaining = route.distance;
      _durationRemaining = route.duration;
      _distanceTraveled = 0;
      _rerouteCount = 0;

      // Keep screen on during navigation
      await WakelockPlus.enable();

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Start GPS tracking
      _startPositionStream();

      // Start navigation
      _state = NavigationState.navigating;
      notifyListeners();

      // Announce start
      if (_voiceEnabled) {
        await _speak('Starting navigation to $_destinationName. ${_steps.first.instruction}');
      }

      return true;
    } catch (e) {
      debugPrint('NavigationService: Failed to start navigation - $e');
      _state = NavigationState.error;
      onError?.call('Failed to start navigation: $e');
      notifyListeners();
      return false;
    }
  }

  /// Start GPS position stream
  void _startPositionStream() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('NavigationService: Position stream error - $error');
        onError?.call('GPS signal lost. Please check your location settings.');
      },
    );
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    if (_state != NavigationState.navigating) return;

    _currentPosition = position;
    onPositionUpdate?.call(position);

    // Check for route deviation
    final distanceFromRoute = _calculateDistanceFromRoute(position);
    if (distanceFromRoute > _deviationThreshold) {
      _handleRouteDeviation();
      return;
    }

    // Update progress
    _updateProgress(position);

    // Check for step advancement
    _checkStepAdvancement(position);

    // Check for arrival
    _checkArrival(position);

    notifyListeners();
  }

  /// Calculate distance from current position to route line
  double _calculateDistanceFromRoute(Position position) {
    if (_routeCoordinates.isEmpty) return 0;

    double minDistance = double.infinity;

    for (int i = 0; i < _routeCoordinates.length - 1; i++) {
      final p1 = _routeCoordinates[i];
      final p2 = _routeCoordinates[i + 1];

      final distance = _distanceToLineSegment(
        position.latitude, position.longitude,
        p1[1], p1[0], // lat, lng
        p2[1], p2[0],
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Calculate perpendicular distance from point to line segment
  double _distanceToLineSegment(
    double px, double py,
    double x1, double y1,
    double x2, double y2,
  ) {
    final A = px - x1;
    final B = py - y1;
    final C = x2 - x1;
    final D = y2 - y1;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    double param = -1;

    if (lenSq != 0) {
      param = dot / lenSq;
    }

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    return _calculateDistance(px, py, xx, yy);
  }

  /// Handle route deviation - trigger rerouting
  Future<void> _handleRouteDeviation() async {
    if (_state == NavigationState.rerouting) return;
    if (_rerouteCount >= _maxReroutes) {
      onError?.call('Unable to find route. Please check your destination.');
      return;
    }

    _state = NavigationState.rerouting;
    _rerouteCount++;
    notifyListeners();

    if (_voiceEnabled) {
      await _speak('Recalculating route');
    }
    onRerouting?.call('Recalculating route...');

    try {
      // Request new route from current position
      final newRoute = await _directionsService.getWalkingRoute(
        origin: [_currentPosition!.longitude, _currentPosition!.latitude],
        destination: _destination!,
      );

      if (newRoute != null) {
        // Update route data
        _route = newRoute;
        _steps = newRoute.routes.first.legs.first.steps;
        _currentStepIndex = 0;
        _routeCoordinates = newRoute.routes.first.coordinates;
        _distanceRemaining = newRoute.distance;
        _durationRemaining = newRoute.duration;

        _state = NavigationState.navigating;
        notifyListeners();

        if (_voiceEnabled) {
          await _speak('Route updated. ${_steps.first.instruction}');
        }
      } else {
        _state = NavigationState.navigating;
        onError?.call('Could not find alternative route');
      }
    } catch (e) {
      debugPrint('NavigationService: Rerouting failed - $e');
      _state = NavigationState.navigating;
      onError?.call('Rerouting failed: $e');
    }

    notifyListeners();
  }

  /// Update navigation progress
  void _updateProgress(Position position) {
    if (_destination == null) return;

    // Calculate distance to destination
    _distanceRemaining = _calculateDistance(
      position.latitude, position.longitude,
      _destination![1], _destination![0],
    );

    // Estimate remaining duration (walking speed ~1.4 m/s)
    _durationRemaining = _distanceRemaining / 1.4;

    // Calculate distance traveled
    _distanceTraveled = _totalDistance - _distanceRemaining;
    if (_distanceTraveled < 0) _distanceTraveled = 0;

    // Calculate distance to next step
    if (currentStep != null && _currentStepIndex < _routeCoordinates.length) {
      // Find the end point of current step
      final stepEndIndex = _findStepEndCoordinateIndex(_currentStepIndex);
      if (stepEndIndex < _routeCoordinates.length) {
        final stepEnd = _routeCoordinates[stepEndIndex];
        _distanceToNextStep = _calculateDistance(
          position.latitude, position.longitude,
          stepEnd[1], stepEnd[0],
        );
      }
    }
  }

  /// Find the coordinate index where a step ends
  int _findStepEndCoordinateIndex(int stepIndex) {
    double accumulatedDistance = 0;
    double targetDistance = 0;

    for (int i = 0; i <= stepIndex && i < _steps.length; i++) {
      targetDistance += _steps[i].distance;
    }

    for (int i = 0; i < _routeCoordinates.length - 1; i++) {
      final p1 = _routeCoordinates[i];
      final p2 = _routeCoordinates[i + 1];
      accumulatedDistance += _calculateDistance(p1[1], p1[0], p2[1], p2[0]);

      if (accumulatedDistance >= targetDistance) {
        return i + 1;
      }
    }

    return _routeCoordinates.length - 1;
  }

  /// Check if user should advance to next step
  void _checkStepAdvancement(Position position) {
    if (currentStep == null) return;

    // Advance to next step when within 15m of step end or passed it
    if (_distanceToNextStep < 15 && _currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      onStepChange?.call(_currentStepIndex);

      // Announce next instruction
      if (_voiceEnabled && currentStep != null) {
        _announceStep(currentStep!);
      }

      notifyListeners();
    }
    // Pre-announce upcoming turn at 50m
    else if (_distanceToNextStep < 50 && _distanceToNextStep > 45 && nextStep != null) {
      if (_voiceEnabled) {
        _speak('In ${_distanceToNextStep.round()} meters, ${nextStep!.instruction}');
      }
    }
  }

  /// Check if user has arrived at destination
  void _checkArrival(Position position) {
    if (_destination == null) return;

    final distanceToDestination = _calculateDistance(
      position.latitude, position.longitude,
      _destination![1], _destination![0],
    );

    // Arrived when within 10 meters of destination
    if (distanceToDestination < 10) {
      _handleArrival();
    }
  }

  /// Handle arrival at destination
  Future<void> _handleArrival() async {
    _state = NavigationState.arrived;
    notifyListeners();

    if (_voiceEnabled) {
      await _speak('You have arrived at your destination, $_destinationName');
    }

    onArrival?.call();

    // Clean up
    await Future.delayed(const Duration(seconds: 3));
    await stopNavigation();
  }

  /// Announce a navigation step
  Future<void> _announceStep(RouteStep step) async {
    String instruction = step.instruction;

    // Add distance context
    if (step.distance > 100) {
      instruction = '$instruction for ${(step.distance / 1000).toStringAsFixed(1)} kilometers';
    } else if (step.distance > 20) {
      instruction = '$instruction for ${step.distance.round()} meters';
    }

    await _speak(instruction);
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('NavigationService: TTS error - $e');
    }
  }

  /// Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  /// Toggle voice guidance
  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    notifyListeners();

    if (_voiceEnabled) {
      _speak('Voice guidance enabled');
    }
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    await _tts.stop();
    await WakelockPlus.disable();

    _state = NavigationState.idle;
    _route = null;
    _steps = [];
    _currentStepIndex = 0;
    _routeCoordinates = [];
    _origin = null;
    _destination = null;
    _originName = null;
    _destinationName = null;
    _distanceRemaining = 0;
    _durationRemaining = 0;
    _distanceToNextStep = 0;
    _totalDistance = 0;
    _distanceTraveled = 0;
    _rerouteCount = 0;

    notifyListeners();
  }

  /// Get formatted distance string
  String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  /// Get formatted duration string
  String formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
    return '$minutes min';
  }

  @override
  void dispose() {
    stopNavigation();
    _tts.stop();
    super.dispose();
  }
}
