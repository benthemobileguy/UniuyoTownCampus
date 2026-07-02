import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/mapbox_directions_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/coordinate_transformer.dart';

/// Full-screen real-time navigation page
class NavigationPage extends StatefulWidget {
  final DirectionsResponse route;
  final List<double> origin; // [lng, lat]
  final List<double> destination; // [lng, lat]
  final String originName;
  final String destinationName;

  const NavigationPage({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final NavigationService _navigationService = NavigationService();
  MapboxMap? _mapboxMap;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    await _navigationService.initialize();

    // Set up callbacks
    _navigationService.onPositionUpdate = _onPositionUpdate;
    _navigationService.onStepChange = _onStepChange;
    _navigationService.onArrival = _onArrival;
    _navigationService.onRerouting = _onRerouting;
    _navigationService.onError = _onError;

    // Add listener for state changes
    _navigationService.addListener(_onNavigationStateChange);

    // Start navigation
    final success = await _navigationService.startNavigation(
      route: widget.route,
      origin: widget.origin,
      destination: widget.destination,
      originName: widget.originName,
      destinationName: widget.destinationName,
    );

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Failed to start navigation. Please check GPS settings.';
      });
    }
  }

  void _onNavigationStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onPositionUpdate(geo.Position geoPosition) {
    _updateUserLocationOnMap(geoPosition);
  }

  void _onStepChange(int stepIndex) {
    HapticFeedback.mediumImpact();
  }

  void _onArrival() {
    HapticFeedback.heavyImpact();
    _showArrivalDialog();
  }

  void _onRerouting(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange[700],
      ),
    );
  }

  void _onError(String error) {
    setState(() {
      _errorMessage = error;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text('You Have Arrived!'),
        content: Text(
          'You have reached ${widget.destinationName}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserLocationOnMap(geo.Position geoPosition) async {
    if (_mapboxMap == null) return;

    try {
      // Update camera to follow user
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(geoPosition.longitude, geoPosition.latitude),
          ),
          zoom: 18.0,
          bearing: geoPosition.heading,
          pitch: 45.0, // 3D perspective during navigation
        ),
        MapAnimationOptions(duration: 500),
      );
    } catch (e) {
      debugPrint('NavigationPage: Failed to update camera - $e');
    }
  }

  @override
  void dispose() {
    _navigationService.removeListener(_onNavigationStateChange);
    _navigationService.stopNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey("navigationMap"),
            onMapCreated: _onMapCreated,
          ),

          // Top instruction card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildInstructionCard(),
          ),

          // Bottom progress panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProgressPanel(),
          ),

          // Loading overlay
          if (_navigationService.state == NavigationState.preparing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Starting Navigation...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Rerouting overlay
          if (_navigationService.state == NavigationState.rerouting)
            Positioned(
              top: MediaQuery.of(context).padding.top + 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recalculating Route...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    final currentStep = _navigationService.currentStep;
    final nextStep = _navigationService.nextStep;
    final distanceToNext = _navigationService.distanceToNextStep;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.colorPrimary,
            AppColors.colorPrimary.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Current instruction
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Direction icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDirectionIcon(currentStep?.instruction ?? ''),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Instruction text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _navigationService.formatDistance(distanceToNext),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStep?.instruction ?? 'Calculating...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Next turn preview
            if (nextStep != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.black.withOpacity(0.2),
                child: Row(
                  children: [
                    const Text(
                      'Then',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getDirectionIcon(nextStep.instruction),
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextStep.instruction,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressPanel() {
    final distanceRemaining = _navigationService.distanceRemaining;
    final durationRemaining = _navigationService.durationRemaining;
    final progress = _navigationService.totalDistance > 0
        ? _navigationService.distanceTraveled / _navigationService.totalDistance
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.originName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.destinationName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(AppColors.colorPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.straighten,
                    value: _navigationService.formatDistance(distanceRemaining),
                    label: 'Remaining',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(
                    icon: Icons.access_time,
                    value: _navigationService.formatDuration(durationRemaining),
                    label: 'ETA',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(
                    icon: Icons.directions_walk,
                    value: '${_navigationService.currentStepIndex + 1}/${_navigationService.steps.length}',
                    label: 'Steps',
                  ),
                ],
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Mute/unmute button
                  Material(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _navigationService.toggleVoice();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        child: Icon(
                          _navigationService.voiceEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: _navigationService.voiceEnabled
                              ? AppColors.colorPrimary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stop navigation button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stopNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Stop Navigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.colorPrimary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  IconData _getDirectionIcon(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('left')) return Icons.turn_left;
    if (lower.contains('right')) return Icons.turn_right;
    if (lower.contains('straight') || lower.contains('continue')) {
      return Icons.straight;
    }
    if (lower.contains('arrive') || lower.contains('destination')) {
      return Icons.location_on;
    }
    if (lower.contains('u-turn')) return Icons.u_turn_left;
    return Icons.navigation;
  }

  void _stopNavigation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation?'),
        content: const Text('Are you sure you want to stop navigating?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Set initial camera
    final firstCoord = widget.route.routes.first.coordinates.first;
    await _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(firstCoord[0], firstCoord[1])),
        zoom: 17.0,
        pitch: 45.0,
      ),
    );

    // Enable location tracking
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: AppColors.primary.value,
        showAccuracyRing: true,
      ),
    );

    // Draw route on map
    await _drawRoute();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _drawRoute() async {
    try {
      final routeGeometry = widget.route.routes.first.geometry;

      // Add route source
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'navigation-route-source',
          data: json.encode(routeGeometry),
        ),
      );

      // Add route border
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: 'navigation-route-border',
          sourceId: 'navigation-route-source',
          lineColor: const Color(0xFF1565C0).value,
          lineWidth: 10.0,
          lineOpacity: 0.4,
        ),
      );

      // Add route line
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: 'navigation-route-line',
          sourceId: 'navigation-route-source',
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 6.0,
          lineOpacity: 1.0,
        ),
      );

      // Add destination marker
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'destination-source',
          data: json.encode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {},
                "geometry": {
                  "type": "Point",
                  "coordinates": widget.destination,
                }
              }
            ]
          }),
        ),
      );

      await _mapboxMap?.style.addLayer(
        CircleLayer(
          id: 'destination-marker',
          sourceId: 'destination-source',
          circleRadius: 12.0,
          circleColor: Colors.red.value,
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.value,
        ),
      );
    } catch (e) {
      debugPrint('NavigationPage: Failed to draw route - $e');
    }
  }
}
