import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/providers/recent_searches_provider.dart';
import '../../../../core/services/mapbox_directions_service.dart' as mapbox;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/coordinate_transformer.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/route_summary_card.dart';
import '../../../../core/widgets/building_details_sheet.dart';
import '../../../navigation/presentation/pages/navigation_page.dart';
import '../../data/providers/campus_data_providers.dart';
import '../../domain/entities/building.dart';

/// Directions page matching DirectionsActivity.kt
class DirectionsPage extends ConsumerStatefulWidget {
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLng;

  const DirectionsPage({
    super.key,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  ConsumerState<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends ConsumerState<DirectionsPage> {
  MapboxMap? _mapboxMap;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final mapbox.MapboxDirectionsService _directionsService = mapbox.MapboxDirectionsService();

  Building? _originBuilding;
  Building? _destinationBuilding;
  mapbox.DirectionsResponse? _currentRoute;
  int _selectedRouteIndex = 0; // Index of selected route alternative
  bool _mapReady = false;
  bool _loadingRoute = false;
  String _selectedRouteType = 'shortest'; // 'shortest' or 'accessible'
  bool _is3DMode = false; // 3D buildings toggle
  bool _showPOIs = false; // POI layer toggle

  // From DirectionsActivity.kt line 216, 67-68
  static const double _defaultLat = 5.0409083;
  static const double _defaultLng = 7.9235053;
  static const double _defaultZoom = AppDimensions.mapZoomDefault; // 15.0

  @override
  void initState() {
    super.initState();

    // Pre-fill destination if provided
    if (widget.destinationName != null) {
      _toController.text = widget.destinationName!;
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingNamesAsync = ref.watch(buildingNamesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("directionsMap"),
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTapped,
          ),

          // Top Header - UOB Style (full width, covers safe area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5), // Light gray background
                ),
                child: buildingNamesAsync.when(
                  data: (buildingNames) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // From field
                      _buildAutocompleteField(
                        controller: _fromController,
                        hint: 'From',
                        icon: Icons.my_location,
                        buildingNames: buildingNames,
                        onSelected: (name) => _onFromSelected(name),
                      ),
                      const SizedBox(height: 8),
                      // To field
                      _buildAutocompleteField(
                        controller: _toController,
                        hint: 'To',
                        icon: Icons.location_on,
                        buildingNames: buildingNames,
                        onSelected: (name) => _onToSelected(name),
                      ),

                      // Route Type Toggle Buttons (UOB-style)
                      if (_originBuilding != null && _destinationBuilding != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Shortest route button
                            Expanded(
                              child: _buildRouteTypeButton(
                                label: 'Shortest',
                                icon: Icons.directions_walk,
                                isSelected: _selectedRouteType == 'shortest',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedRouteType = 'shortest';
                                  });
                                  _requestRoute();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Step-free route button
                            Expanded(
                              child: _buildRouteTypeButton(
                                label: 'Step-free',
                                icon: Icons.accessible,
                                isSelected: _selectedRouteType == 'accessible',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedRouteType = 'accessible';
                                  });
                                  _requestRoute();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Green Route Info Bar (when route exists)
                      if (_currentRoute != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399), // Emerald green - better blend
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                '1 Stage',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              Text(
                                '${(_currentRoute!.routes[_selectedRouteIndex].distance / 1000).toStringAsFixed(1)} km (${(_currentRoute!.routes[_selectedRouteIndex].duration / 60).toStringAsFixed(0)} mins)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              Text(
                                _selectedRouteType == 'shortest' ? 'Shortest' : 'Step-free',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Start Route Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _loadingRoute ? null : _startNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B4C7D), // UOB purple
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Start Route',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ),
            ),
          ),

          // Back Button (on top of header)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              color: AppColors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.colorPrimary,
              ),
            ),
          ),

          // Loading indicator
          if (_loadingRoute)
            const Positioned.fill(
              child: OverlayLoadingWidget(
                message: 'Calculating route...',
              ),
            ),

          // Map Controls - All icon buttons in one aligned column
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D Toggle Button
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: _is3DMode ? AppColors.colorPrimary : AppColors.white,
                    child: IconButton(
                      icon: Icon(
                        Icons.view_in_ar,
                        color: _is3DMode ? AppColors.white : AppColors.colorPrimary,
                        size: 24,
                      ),
                      onPressed: _toggle3DMode,
                      tooltip: '3D Buildings',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Zoom In
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 24),
                      onPressed: _zoomIn,
                      color: AppColors.colorPrimary,
                      tooltip: 'Zoom In',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Zoom Out
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 24),
                      onPressed: _zoomOut,
                      color: AppColors.colorPrimary,
                      tooltip: 'Zoom Out',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // POI Toggle
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: _showPOIs ? AppColors.colorPrimary : AppColors.white,
                    child: IconButton(
                      icon: Icon(
                        Icons.place,
                        color: _showPOIs ? AppColors.white : AppColors.colorPrimary,
                        size: 24,
                      ),
                      onPressed: _togglePOIs,
                      tooltip: 'Facilities',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // My Location
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.my_location, size: 24),
                      onPressed: _goToDefaultLocation,
                      color: AppColors.colorPrimary,
                      tooltip: 'My Location',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Route alternatives (if multiple routes available)
          if (_currentRoute != null && _currentRoute!.routes.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 80, // Leave space for zoom buttons
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        'Route Options',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    ...List.generate(
                      _currentRoute!.routes.length.clamp(0, 3), // Max 3 routes
                      (index) {
                        final route = _currentRoute!.routes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: CompactRouteSummary(
                            distanceMeters: route.distance,
                            durationMinutes: (route.duration / 60).round(),
                            routeType: index == 0 ? 'Fastest' : 'Alternative ${index}',
                            isSelected: _selectedRouteIndex == index,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedRouteIndex = index;
                              });
                              _drawRoute(_currentRoute!);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Route summary now in header (UOB-style)
        ],
      ),
    );
  }

  // Map control methods
  void _zoomIn() async {
    HapticFeedback.lightImpact();
    final currentZoom = await _mapboxMap?.getCameraState();
    if (currentZoom != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          zoom: (currentZoom.zoom + 1).clamp(0, 22),
        ),
      );
    }
  }

  void _zoomOut() async {
    HapticFeedback.lightImpact();
    final currentZoom = await _mapboxMap?.getCameraState();
    if (currentZoom != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          zoom: (currentZoom.zoom - 1).clamp(0, 22),
        ),
      );
    }
  }

  void _toggle3DMode() async {
    HapticFeedback.mediumImpact();

    setState(() {
      _is3DMode = !_is3DMode;
    });

    try {
      final currentState = await _mapboxMap?.getCameraState();

      if (_is3DMode) {
        // Switch to 3D view with tilted camera
        _mapboxMap?.setCamera(
          CameraOptions(
            pitch: 45.0, // Tilt camera for 3D effect
            zoom: currentState?.zoom,
          ),
        );

        debugPrint('✅ DirectionsPage: 3D mode enabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('3D Buildings Enabled'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Switch back to 2D view
        _mapboxMap?.setCamera(
          CameraOptions(
            pitch: 0.0, // Flat camera
            zoom: currentState?.zoom,
          ),
        );

        debugPrint('✅ DirectionsPage: 2D mode restored');
      }
    } catch (e) {
      debugPrint('❌ DirectionsPage: Error toggling 3D mode - $e');
    }
  }

  void _togglePOIs() async {
    HapticFeedback.lightImpact();

    setState(() {
      _showPOIs = !_showPOIs;
    });

    try {
      if (_showPOIs) {
        // Add POI markers layer
        await _addPOILayer();

        debugPrint('✅ DirectionsPage: POI layer enabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Showing Facilities'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Remove POI layer
        try {
          await _mapboxMap?.style.removeStyleLayer('poi-layer');
          await _mapboxMap?.style.removeStyleSource('poi-source');
        } catch (e) {
          // Layer doesn't exist
        }

        debugPrint('✅ DirectionsPage: POI layer disabled');
      }
    } catch (e) {
      debugPrint('❌ DirectionsPage: Error toggling POIs - $e');
    }
  }

  Future<void> _addPOILayer() async {
    try {
      // Sample POI data (can be expanded with real campus data)
      final pois = {
        "type": "FeatureCollection",
        "features": [
          // Cafeteria/Restaurant icons
          {
            "type": "Feature",
            "properties": {"icon": "🍽️", "name": "Main Cafeteria"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9235, 5.0410] // Campus center area
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "☕", "name": "Coffee Shop"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9228, 5.0415]
            }
          },
          // Toilet icons
          {
            "type": "Feature",
            "properties": {"icon": "🚻", "name": "Restroom Block A"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9240, 5.0408]
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "🚻", "name": "Restroom Block B"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9230, 5.0412]
            }
          },
          // ATM icons
          {
            "type": "Feature",
            "properties": {"icon": "🏧", "name": "ATM"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9238, 5.0405]
            }
          },
          // Parking icons
          {
            "type": "Feature",
            "properties": {"icon": "🅿️", "name": "Main Parking"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9242, 5.0418]
            }
          },
        ]
      };

      // Add POI source
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'poi-source',
          data: json.encode(pois),
        ),
      );

      // Add POI symbol layer
      await _mapboxMap?.style.addLayer(
        SymbolLayer(
          id: 'poi-layer',
          sourceId: 'poi-source',
          textField: "{icon}",
          textSize: 24.0,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
      );

      debugPrint('✅ DirectionsPage: POI layer added');
    } catch (e) {
      debugPrint('❌ DirectionsPage: Error adding POI layer - $e');
    }
  }

  void _goToDefaultLocation() async {
    HapticFeedback.mediumImpact();

    // Fly to default campus center location
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_defaultLng, _defaultLat)),
        zoom: _defaultZoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const R = 6371000; // Earth radius in meters
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  Future<void> _fitCameraToRoute(mapbox.Route route) async {
    try {
      // Get route coordinates
      final coordinates = route.coordinates;
      if (coordinates.isEmpty) return;

      // Calculate bounding box
      double minLng = coordinates.first[0];
      double maxLng = coordinates.first[0];
      double minLat = coordinates.first[1];
      double maxLat = coordinates.first[1];

      for (final coord in coordinates) {
        minLng = math.min(minLng, coord[0]);
        maxLng = math.max(maxLng, coord[0]);
        minLat = math.min(minLat, coord[1]);
        maxLat = math.max(maxLat, coord[1]);
      }

      // Add padding to bounds
      const padding = 0.002; // ~200m padding
      minLng -= padding;
      maxLng += padding;
      minLat -= padding;
      maxLat += padding;

      // Fly camera to fit bounds
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              (minLng + maxLng) / 2,
              (minLat + maxLat) / 2,
            ),
          ),
          padding: MbxEdgeInsets(
            top: 200,
            left: 50,
            bottom: 300,
            right: 50,
          ),
        ),
        MapAnimationOptions(duration: 1500),
      );

      debugPrint('✅ DirectionsPage: Camera fitted to route bounds');
    } catch (e) {
      debugPrint('❌ DirectionsPage: Error fitting camera - $e');
    }
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required List<String> buildingNames,
    required Function(String) onSelected,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.colorPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              // Show recent searches when empty
              if (textEditingValue.text.isEmpty) {
                final recentSearches = await ref.read(recentSearchesServiceProvider).getRecentSearches();
                // Filter to only valid building names
                return recentSearches.where((name) => buildingNames.contains(name));
              }

              // Show matching buildings as user types
              return buildingNames.where((name) {
                return name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    width: MediaQuery.of(context).size.width - 64,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return FutureBuilder<List<Building>>(
                          future: ref.read(buildingsProvider.future),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return ListTile(title: Text(option));
                            }

                            final building = snapshot.data!.firstWhere(
                              (b) => b.name == option,
                              orElse: () => snapshot.data!.first,
                            );

                            return ListTile(
                              leading: Icon(
                                _getBuildingIcon(building.buildingFunction),
                                color: _getBuildingColor(building.buildingFunction),
                                size: 20,
                              ),
                              title: Text(
                                building.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                              subtitle: Text(
                                building.buildingFunction,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                              dense: true,
                              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: onSelected,
            fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
              // Sync with our controller
              fieldController.text = controller.text;
              fieldController.addListener(() {
                controller.text = fieldController.text;
              });

              return TextField(
                controller: fieldController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getBuildingIcon(String function) {
    final lowerFunction = function.toLowerCase();
    // New GeoJSON Category values: Academic Unit, Adminstrative Unit, Hostel, etc.
    if (lowerFunction.contains('academic') && !lowerFunction.contains('admin')) {
      return Icons.school; // Academic buildings
    }
    if (lowerFunction.contains('admin')) return Icons.business; // Administrative
    if (lowerFunction.contains('hostel')) return Icons.home; // Hostels
    if (lowerFunction.contains('sport')) return Icons.sports;
    if (lowerFunction.contains('parking')) return Icons.local_parking;
    if (lowerFunction.contains('construction')) return Icons.construction;
    // Legacy support for old values
    if (lowerFunction.contains('library')) return Icons.local_library;
    if (lowerFunction.contains('laboratory') || lowerFunction.contains('classrooms')) {
      return Icons.science;
    }
    if (lowerFunction.contains('cafeteria') || lowerFunction.contains('food')) {
      return Icons.restaurant;
    }
    if (lowerFunction.contains('medical') || lowerFunction.contains('health')) {
      return Icons.local_hospital;
    }
    return Icons.apartment;
  }

  Color _getBuildingColor(String function) {
    final lowerFunction = function.toLowerCase();
    // New GeoJSON Category values: Academic Unit, Adminstrative Unit, Hostel, etc.
    if (lowerFunction.contains('academic') && !lowerFunction.contains('admin')) {
      return const Color(0xFFD32F2F); // Red for academic
    }
    if (lowerFunction.contains('admin')) return const Color(0xFFEF6C00); // Orange for admin
    if (lowerFunction.contains('hostel')) return const Color(0xFF512DA8); // Purple for hostels
    if (lowerFunction.contains('sport')) return const Color(0xFF0288D1); // Blue for sports
    if (lowerFunction.contains('parking')) return const Color(0xFF757575); // Gray for parking
    if (lowerFunction.contains('construction')) return const Color(0xFFFFA000); // Amber for construction
    // Legacy support for old values
    if (lowerFunction.contains('library')) return const Color(0xFF512DA8);
    if (lowerFunction.contains('laboratory') || lowerFunction.contains('classrooms')) {
      return const Color(0xFFD32F2F);
    }
    if (lowerFunction.contains('cafeteria') || lowerFunction.contains('food')) {
      return const Color(0xFFFFA000);
    }
    if (lowerFunction.contains('medical') || lowerFunction.contains('health')) {
      return const Color(0xFFC2185B);
    }
    return AppColors.textSecondary;
  }

  Widget _buildRouteTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5B4C7D) // UOB purple
                : AppColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B4C7D)
                  : AppColors.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Set initial camera position
    _mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(_defaultLng, _defaultLat)),
        zoom: _defaultZoom,
      ),
    );

    // Enable live location tracking (blue puck)
    _enableLocationTracking();

    debugPrint('🗺️ DirectionsPage: Map created, waiting for style to load...');

    // Wait a bit for style to load before adding layers
    await Future.delayed(const Duration(milliseconds: 500));

    // Load map style and add GeoJSON layers
    _setupMap();
  }

  Future<void> _enableLocationTracking() async {
    try {
      debugPrint('📍 DirectionsPage: Enabling location tracking...');

      // Enable location puck
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true, // Pulsing blue dot like UOB
          pulsingColor: AppColors.primary.value,
          pulsingMaxRadius: 20.0,
          showAccuracyRing: true,
          accuracyRingColor: AppColors.primary.withOpacity(0.2).value,
          accuracyRingBorderColor: AppColors.primary.withOpacity(0.4).value,
        ),
      );

      debugPrint('✅ DirectionsPage: Location tracking enabled');
    } catch (e) {
      debugPrint('❌ DirectionsPage: Failed to enable location tracking - $e');
    }
  }

  Future<void> _setupMap() async {
    try {
      debugPrint('🗺️ DirectionsPage: Loading GeoJSON files from assets...');
      // Load GeoJSON files from assets
      final buildingsJson = await rootBundle.loadString('assets/geojson/Buildings111.geojson');
      debugPrint('✅ DirectionsPage: Buildings GeoJSON loaded (${buildingsJson.length} chars)');
      final roadsJson = await rootBundle.loadString('assets/geojson/Roads111.geojson');
      debugPrint('✅ DirectionsPage: Roads GeoJSON loaded (${roadsJson.length} chars)');

      // Transform GeoJSON from UTM to WGS84
      debugPrint('🔄 DirectionsPage: Transforming coordinates from UTM to WGS84...');
      final transformedBuildingsJson = await _transformGeoJson(buildingsJson);
      debugPrint('✅ DirectionsPage: Buildings coordinates transformed');
      final transformedRoadsJson = await _transformGeoJson(roadsJson);
      debugPrint('✅ DirectionsPage: Roads coordinates transformed');

      // Add GeoJSON sources
      debugPrint('📍 DirectionsPage: Adding GeoJSON sources to map...');
      // Source WITHOUT clustering for polygon fills
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "buildings-source",
          data: transformedBuildingsJson,
          cluster: false, // No clustering - keeps MultiPolygon geometry for fills
        ),
      );
      debugPrint('✅ DirectionsPage: Buildings polygon source added');

      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "roads-source",
          data: transformedRoadsJson,
        ),
      );
      debugPrint('✅ DirectionsPage: Roads source added');

      // Clusters removed - buildings show as filled polygons like UOB

      // Add color-coded fill layers for buildings (UOB-style)
      debugPrint('🎨 DirectionsPage: Adding color-coded building layers...');

      // Default - Light tan/beige for ALL buildings (base layer)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-default-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFBCAAA4).value, // Light tan/beige
          fillOpacity: 0.7,
        ),
      );

      // Academic buildings - Red (rendered on top)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-academic-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFD32F2F).value, // Red like UOB academic
          fillOpacity: 0.75,
          filter: [
            "any",
            ["==", ["get", "Category"], "Academic Unit"],
            ["==", ["get", "Category"], "Academic unit"],
            ["==", ["get", "Category"], "Academic Uni"],
            ["==", ["get", "Category"], "Academic"],
            ["==", ["get", "Category"], "Academic/Adminstarative Unit"],
            ["==", ["get", "Category"], "Academic/Adminstartive Unit"],
            ["==", ["get", "Category"], "Academic/Adminstative Unit"],
            ["==", ["get", "Category"], "Academic/Adminstration Unit"],
            ["==", ["get", "Category"], "Academic/Adminstrative Unit"],
            ["==", ["get", "Category"], "Academiic/Adminstrative Unit"],
          ],
        ),
      );

      // Administrative - Orange
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-admin-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFEF6C00).value, // Orange
          fillOpacity: 0.75,
          filter: [
            "any",
            ["==", ["get", "Category"], "Adminstrative Unit"],
            ["==", ["get", "Category"], "Adminstrative unit"],
            ["==", ["get", "Category"], "Adminstrative"],
            ["==", ["get", "Category"], "Adminstative Unit"],
            ["==", ["get", "Category"], "Adminstravive Unit"],
          ],
        ),
      );

      // Hostels - Deep Purple
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-hostel-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFF512DA8).value, // Purple
          fillOpacity: 0.75,
          filter: [
            "any",
            ["==", ["get", "Category"], "Hostel"],
            ["==", ["get", "Category"], "Hostels"],
          ],
        ),
      );

      // Sports/Other facilities - Pink
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-other-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFC2185B).value, // Pink
          fillOpacity: 0.75,
          filter: [
            "any",
            ["==", ["get", "Category"], "Sports facility"],
            ["==", ["get", "Category"], "Parking lot"],
            ["==", ["get", "Category"], "Other"],
            ["==", ["get", "Category"], "Others"],
          ],
        ),
      );
      debugPrint('✅ DirectionsPage: Color-coded building layers added');

      // Add outline layer for ALL buildings for better definition
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "buildings-outline-layer",
          sourceId: "buildings-source",
          lineColor: const Color(0xFF616161).value, // Dark gray
          lineOpacity: 0.6,
          lineWidth: 1.0,
        ),
      );
      debugPrint('✅ DirectionsPage: Buildings outline layer added');

      // Add building name labels (UOB-style)
      await _mapboxMap?.style.addLayer(
        SymbolLayer(
          id: "buildings-labels-layer",
          sourceId: "buildings-source",
          textField: "{Name}", // Building names from new GeoJSON format
          textSize: 11.0,
          textColor: const Color(0xFF263238).value, // Dark blue-gray
          textHaloColor: Colors.white.value,
          textHaloWidth: 2.0,
          textHaloBlur: 1.0,
          textAllowOverlap: false, // Don't clutter
          textOptional: true,
          textAnchor: TextAnchor.CENTER,
          minZoom: 15.5, // Only show when zoomed in
        ),
      );
      debugPrint('✅ DirectionsPage: Building labels layer added');

      // Add line layer for roads
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "roads-line-layer",
          sourceId: "roads-source",
          lineColor: AppColors.roadColor.value,
          lineOpacity: AppColors.roadOpacity,
          lineWidth: 2.0,
        ),
      );
      debugPrint('✅ DirectionsPage: Roads line layer added');

      setState(() {
        _mapReady = true;
      });
      debugPrint('🎉 DirectionsPage: Map setup complete! Buildings and roads visible.');
    } catch (e) {
      debugPrint('❌ DirectionsPage ERROR: Failed to setup map - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load map data: $e')),
        );
      }
    }
  }

  /// Transform GeoJSON coordinates from UTM EPSG:32632 to WGS84
  Future<String> _transformGeoJson(String geoJsonString) async {
    final geoJson = json.decode(geoJsonString) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;

    for (var feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final coords = geometry['coordinates'];

      if (type == 'MultiPolygon') {
        geometry['coordinates'] = _transformMultiPolygon(coords);
      } else if (type == 'MultiLineString') {
        geometry['coordinates'] = _transformMultiLineString(coords);
      }
    }

    return json.encode(geoJson);
  }

  List<dynamic> _transformMultiPolygon(dynamic coords) {
    return (coords as List).map((polygon) {
      return (polygon as List).map((ring) {
        return (ring as List).map((coord) {
          final coordList = coord as List;
          final point = CoordinateTransformer.utmToWgs84(
            easting: (coordList[0] as num).toDouble(),
            northing: (coordList[1] as num).toDouble(),
          );
          return [point.longitude, point.latitude];
        }).toList();
      }).toList();
    }).toList();
  }

  List<dynamic> _transformMultiLineString(dynamic coords) {
    return (coords as List).map((lineString) {
      return (lineString as List).map((coord) {
        final coordList = coord as List;
        final point = CoordinateTransformer.utmToWgs84(
          easting: (coordList[0] as num).toDouble(),
          northing: (coordList[1] as num).toDouble(),
        );
        return [point.longitude, point.latitude];
      }).toList();
    }).toList();
  }

  void _onMapTapped(MapContentGestureContext context) async {
    debugPrint('👆 DirectionsPage: Map tapped at position ${context.touchPosition}');
    // Query for buildings at tap location - check all building fill layers
    final features = await _mapboxMap?.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
      RenderedQueryOptions(layerIds: [
        "buildings-default-layer",
        "buildings-academic-layer",
        "buildings-admin-layer",
        "buildings-hostel-layer",
        "buildings-other-layer",
      ]),
    );

    debugPrint('🔍 DirectionsPage: Found ${features?.length ?? 0} features at tap location');
    if (features != null && features.isNotEmpty) {
      HapticFeedback.lightImpact(); // Haptic feedback when building is tapped

      final feature = features.first;
      // Access properties through queriedFeature.feature
      final featureData = feature?.queriedFeature.feature;
      final propertiesRaw = featureData?['properties'];
      final properties = propertiesRaw != null
          ? Map<String, dynamic>.from(propertiesRaw as Map)
          : null;
      final buildingName = properties?['Name'] as String? ?? 'Unknown Building';

      debugPrint('🏢 DirectionsPage: Tapped on building: $buildingName');
      _showBuildingDialog(buildingName);
    } else {
      debugPrint('ℹ️ DirectionsPage: No building found at tap location');
    }
  }

  void _showBuildingDialog(String buildingName) async {
    HapticFeedback.mediumImpact();

    // Find the building object
    final buildings = await ref.read(buildingsProvider.future);
    final building = buildings.firstWhere(
      (b) => b.name == buildingName,
      orElse: () => buildings.first,
    );

    if (!mounted) return;

    // Show professional Material 3 bottom sheet
    BuildingDetailsSheet.show(
      context,
      building: building,
      onGetDirections: () {
        _toController.text = buildingName;
        _onToSelected(buildingName);
      },
      onSetReminder: () {
        // Future implementation: Show reminder picker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder feature coming soon for ${building.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<void> _onFromSelected(String buildingName) async {
    debugPrint('📍 DirectionsPage: Selected FROM building: $buildingName');

    // Save to recent searches
    await ref.read(recentSearchesServiceProvider).saveSearch(buildingName);

    final buildings = await ref.read(buildingsProvider.future);
    debugPrint('📋 DirectionsPage: Total buildings available: ${buildings.length}');
    _originBuilding = buildings.firstWhere(
      (b) => b.displayName == buildingName,
      orElse: () => buildings.first,
    );
    debugPrint('✅ DirectionsPage: Found origin building: ${_originBuilding!.displayName}');

    // Zoom to building
    final centroid = _originBuilding!.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );
    debugPrint('🎯 DirectionsPage: Flying to origin at (${wgs84.latitude}, ${wgs84.longitude})');

    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(wgs84.longitude, wgs84.latitude)),
        zoom: AppDimensions.mapZoomBuilding,
      ),
      MapAnimationOptions(duration: 1000),
    );

    setState(() {});

    // Request route if both origin and destination are set
    if (_destinationBuilding != null) {
      debugPrint('🚀 DirectionsPage: Both origin and destination set, requesting route...');
      _requestRoute();
    }
  }

  Future<void> _onToSelected(String buildingName) async {
    debugPrint('🎯 DirectionsPage: Selected TO building: $buildingName');

    // Save to recent searches
    await ref.read(recentSearchesServiceProvider).saveSearch(buildingName);

    final buildings = await ref.read(buildingsProvider.future);
    debugPrint('📋 DirectionsPage: Total buildings available: ${buildings.length}');
    _destinationBuilding = buildings.firstWhere(
      (b) => b.displayName == buildingName,
      orElse: () => buildings.first,
    );
    debugPrint('✅ DirectionsPage: Found destination building: ${_destinationBuilding!.displayName}');

    // Zoom to building
    final centroid = _destinationBuilding!.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );
    debugPrint('🎯 DirectionsPage: Flying to destination at (${wgs84.latitude}, ${wgs84.longitude})');

    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(wgs84.longitude, wgs84.latitude)),
        zoom: AppDimensions.mapZoomBuilding,
      ),
      MapAnimationOptions(duration: 1000),
    );

    setState(() {});

    // Request route if both origin and destination are set
    if (_originBuilding != null) {
      debugPrint('🚀 DirectionsPage: Both origin and destination set, requesting route...');
      _requestRoute();
    }
  }

  Future<void> _requestRoute() async {
    if (_originBuilding == null || _destinationBuilding == null) return;

    // Show loading state
    setState(() {
      _loadingRoute = true;
      _currentRoute = null; // Clear previous route
    });

    try {
      debugPrint('🗺️ DirectionsPage: Requesting route from ${_originBuilding!.name} to ${_destinationBuilding!.name}');

      // Get origin and destination coordinates in WGS84
      final originCentroid = _originBuilding!.centroid;
      final originWgs84 = CoordinateTransformer.utmToWgs84(
        easting: originCentroid.x,
        northing: originCentroid.y,
      );

      final destCentroid = _destinationBuilding!.centroid;
      final destWgs84 = CoordinateTransformer.utmToWgs84(
        easting: destCentroid.x,
        northing: destCentroid.y,
      );

      // Request route from Mapbox Directions API with timeout
      final route = await _directionsService.getWalkingRoute(
        origin: [originWgs84.longitude, originWgs84.latitude],
        destination: [destWgs84.longitude, destWgs84.latitude],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ DirectionsPage: Route request timed out');
          return null;
        },
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _selectedRouteIndex = 0; // Reset to first route
          _loadingRoute = false;
        });

        // Draw the route on the map
        await _drawRoute(route);

        // Log route info (UI shows in RouteSummaryCard)
        final distanceKm = (route.distance / 1000).toStringAsFixed(2);
        final durationMin = (route.duration / 60).toStringAsFixed(0);
        final numRoutes = route.routes.length;

        debugPrint('✅ DirectionsPage: ${numRoutes} route(s) found! Primary: ${distanceKm}km, ${durationMin}min');

        // Haptic feedback for successful route calculation
        if (mounted) {
          HapticFeedback.mediumImpact();
        }
      } else {
        setState(() {
          _loadingRoute = false;
        });

        debugPrint('❌ DirectionsPage: Failed to get route');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find a route. Please check your internet connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loadingRoute = false;
      });

      debugPrint('❌ DirectionsPage ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _drawRoute(mapbox.DirectionsResponse route) async {
    try {
      debugPrint('🎨 DirectionsPage: Drawing route ${_selectedRouteIndex + 1} on map...');

      // Remove existing route layers and sources
      try {
        await _mapboxMap?.style.removeStyleLayer('route-line-border');
        await _mapboxMap?.style.removeStyleLayer('route-line');
        await _mapboxMap?.style.removeStyleLayer('start-marker-text');
        await _mapboxMap?.style.removeStyleLayer('start-marker');
        await _mapboxMap?.style.removeStyleLayer('end-marker-text');
        await _mapboxMap?.style.removeStyleLayer('end-marker');
        await _mapboxMap?.style.removeStyleSource('route-source');
        await _mapboxMap?.style.removeStyleSource('start-marker-source');
        await _mapboxMap?.style.removeStyleSource('end-marker-source');
      } catch (e) {
        // Layers/sources don't exist yet, that's fine
      }

      // Get origin and destination coordinates
      final originCentroid = _originBuilding!.centroid;
      final originWgs84 = CoordinateTransformer.utmToWgs84(
        easting: originCentroid.x,
        northing: originCentroid.y,
      );

      final destCentroid = _destinationBuilding!.centroid;
      final destWgs84 = CoordinateTransformer.utmToWgs84(
        easting: destCentroid.x,
        northing: destCentroid.y,
      );

      // Get the selected route
      final selectedRoute = route.routes[_selectedRouteIndex];

      // Add route as GeoJSON source
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'route-source',
          data: json.encode(selectedRoute.geometry),
        ),
      );

      // Add route border (wider, darker line)
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: 'route-line-border',
          sourceId: 'route-source',
          lineColor: const Color(0xFF1565C0).value, // Darker blue
          lineWidth: 8.0,
          lineOpacity: 0.4,
        ),
      );

      // Add route line (main route) - solid blue like UOB
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: 'route-line',
          sourceId: 'route-source',
          lineColor: const Color(0xFF2196F3).value, // Bright blue
          lineWidth: 5.0,
          lineOpacity: 0.9,
        ),
      );

      // Auto-fit camera to show entire route
      await _fitCameraToRoute(selectedRoute);

      // Add START marker (UOB-style black bubble)
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'start-marker-source',
          data: json.encode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {"title": "START"},
                "geometry": {
                  "type": "Point",
                  "coordinates": [originWgs84.longitude, originWgs84.latitude],
                }
              }
            ]
          }),
        ),
      );

      // START marker - smaller circle
      await _mapboxMap?.style.addLayer(
        CircleLayer(
          id: 'start-marker',
          sourceId: 'start-marker-source',
          circleRadius: 24.0,
          circleColor: const Color(0xFF2C2C2C).value,
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.value,
          circleOpacity: 1.0,
        ),
      );

      // START text
      await _mapboxMap?.style.addLayer(
        SymbolLayer(
          id: 'start-marker-text',
          sourceId: 'start-marker-source',
          textField: "START",
          textSize: 8.0,
          textColor: Colors.white.value,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          textAnchor: TextAnchor.CENTER,
          symbolZOrder: SymbolZOrder.AUTO,
        ),
      );

      // Add END marker (UOB-style black bubble)
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: 'end-marker-source',
          data: json.encode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {"title": "END"},
                "geometry": {
                  "type": "Point",
                  "coordinates": [destWgs84.longitude, destWgs84.latitude],
                }
              }
            ]
          }),
        ),
      );

      // END marker - smaller circle
      await _mapboxMap?.style.addLayer(
        CircleLayer(
          id: 'end-marker',
          sourceId: 'end-marker-source',
          circleRadius: 24.0,
          circleColor: const Color(0xFF2C2C2C).value,
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.value,
          circleOpacity: 1.0,
        ),
      );

      // END text
      await _mapboxMap?.style.addLayer(
        SymbolLayer(
          id: 'end-marker-text',
          sourceId: 'end-marker-source',
          textField: "END",
          textSize: 8.0,
          textColor: Colors.white.value,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          textAnchor: TextAnchor.CENTER,
          symbolZOrder: SymbolZOrder.AUTO,
        ),
      );

      debugPrint('✅ DirectionsPage: Route drawn with start/end markers');
    } catch (e) {
      debugPrint('❌ DirectionsPage ERROR drawing route: $e');
    }
  }

  void _startNavigation() {
    if (_currentRoute == null || _originBuilding == null || _destinationBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select origin and destination first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    debugPrint('🧭 DirectionsPage: Starting real-time navigation from ${_originBuilding?.name} to ${_destinationBuilding?.name}');

    // Get origin and destination coordinates in WGS84
    final originCentroid = _originBuilding!.centroid;
    final originWgs84 = CoordinateTransformer.utmToWgs84(
      easting: originCentroid.x,
      northing: originCentroid.y,
    );

    final destCentroid = _destinationBuilding!.centroid;
    final destWgs84 = CoordinateTransformer.utmToWgs84(
      easting: destCentroid.x,
      northing: destCentroid.y,
    );

    // Launch full-screen navigation page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NavigationPage(
          route: _currentRoute!,
          origin: [originWgs84.longitude, originWgs84.latitude],
          destination: [destWgs84.longitude, destWgs84.latitude],
          originName: _originBuilding!.displayName,
          destinationName: _destinationBuilding!.displayName,
        ),
      ),
    );
  }

  void _showNavigationInstructions() {
    if (_currentRoute == null) return;

    final selectedRoute = _currentRoute!.routes[_selectedRouteIndex];
    final steps = selectedRoute.legs.first.steps;
    final distanceKm = (selectedRoute.distance / 1000).toStringAsFixed(2);
    final durationMin = (selectedRoute.duration / 60).toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_originBuilding!.name} → ${_destinationBuilding!.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.customGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.straighten, color: AppColors.customGreen),
                        const SizedBox(height: 4),
                        Text('${distanceKm}km', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.customGreen),
                        const SizedBox(height: 4),
                        Text('${durationMin}min', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.directions_walk, color: AppColors.customGreen),
                        const SizedBox(height: 4),
                        Text('${steps.length} steps', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Turn-by-turn directions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Instructions list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final stepDistance = (step.distance).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.colorPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.instruction),
                                Text(
                                  '${stepDistance}m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
