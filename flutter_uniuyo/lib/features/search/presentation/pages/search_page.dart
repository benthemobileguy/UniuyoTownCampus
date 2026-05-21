import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/providers/recent_searches_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/coordinate_transformer.dart';
import '../../../directions/data/providers/campus_data_providers.dart';
import '../../../directions/domain/entities/building.dart';

/// Search page matching SearchActivity.kt
class SearchPage extends ConsumerStatefulWidget {
  final String? initialBuildingName;

  const SearchPage({super.key, this.initialBuildingName});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  MapboxMap? _mapboxMap;
  final TextEditingController _searchController = TextEditingController();
  TextEditingController? _autocompleteController; // Controller for Autocomplete widget
  List<Building> _searchResults = [];
  bool _mapReady = false;
  bool _hasHandledInitialBuilding = false;
  bool _is3DMode = false; // 3D buildings toggle
  bool _showPOIs = false; // POI layer toggle

  // Selected building info to show on map
  Building? _selectedBuilding;
  Offset? _bubblePosition; // Screen position for bubble's pointer/tail

  // From DirectionsActivity.kt line 216, 67-68
  static const double _defaultLat = 5.0409083;
  static const double _defaultLng = 7.9235053;
  static const double _defaultZoom = AppDimensions.mapZoomDefault; // 15.0

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle initial building name if provided and map is ready
    if (!_hasHandledInitialBuilding &&
        _mapReady &&
        widget.initialBuildingName != null) {
      _hasHandledInitialBuilding = true;
      debugPrint('🔎 SearchPage: Handling initial building: ${widget.initialBuildingName}');
      Future.microtask(() => _onBuildingSelected(widget.initialBuildingName!));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch building names for autocomplete
    final buildingNamesAsync = ref.watch(buildingNamesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("searchMap"),
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTapped,
          ),

          // Search Bar Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 60,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: buildingNamesAsync.when(
                data: (buildingNames) => Autocomplete<String>(
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
                  onSelected: (String selection) {
                    _onBuildingSelected(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Capture the controller so we can update it when building is tapped
                    _autocompleteController = controller;

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search buildings...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const TextField(
                  decoration: InputDecoration(
                    hintText: 'Loading buildings...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                error: (error, stack) => const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search buildings...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: AppColors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.colorPrimary,
              ),
            ),
          ),

          // Building info box with pointer tab (like Android speech bubble)
          if (_selectedBuilding != null && _bubblePosition != null)
            Positioned(
              left: 20,
              right: 20,
              // Position bubble just below the building (pointer is 14px tall)
              top: _bubblePosition!.dy + 14, // Exactly at pointer tip height
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _InfoBoxWithPointerPainter(
                    pointerX: _bubblePosition!.dx - 20, // Adjust for container left margin
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 16), // Top padding for pointer
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Building name with function (display name)
                        Text(
                          _selectedBuilding!.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900, // Extra bold
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Coordinate details
                        Text(
                          'Units, Edge, Point',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700, // Bold
                          ),
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final centroid = _selectedBuilding!.centroid;
                            final wgs84 = CoordinateTransformer.utmToWgs84(
                              easting: centroid.x,
                              northing: centroid.y,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'easting = ${centroid.x.toStringAsFixed(2)}, northing = ${centroid.y.toStringAsFixed(2)}, altitude = 0.0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600, // Semi-bold
                                    fontFamily: 'monospace',
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'latitude = ${wgs84.latitude.toStringAsFixed(7)}, longitude = ${wgs84.longitude.toStringAsFixed(7)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600, // Semi-bold
                                    fontFamily: 'monospace',
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Action icons at bottom (like Android)
          if (_selectedBuilding != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionIcon(Icons.location_on, () {
                    debugPrint('Get directions to: ${_selectedBuilding!.displayName}');
                  }),
                  const SizedBox(width: 24),
                  _buildActionIcon(Icons.share, () {
                    debugPrint('Share: ${_selectedBuilding!.displayName}');
                  }),
                  const SizedBox(width: 24),
                  _buildActionIcon(Icons.notifications, () {
                    final buildingName = _selectedBuilding!.displayName;
                    setState(() {
                      _selectedBuilding = null;
                      _bubblePosition = null;
                    });
                    _showReminderPicker(buildingName);
                  }),
                  const SizedBox(width: 24),
                  _buildActionIcon(Icons.comment, () {
                    debugPrint('Comment on: ${_selectedBuilding!.displayName}');
                  }),
                ],
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
                      tooltip: 'Campus Center',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Map control methods
  void _zoomIn() async {
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
    final currentZoom = await _mapboxMap?.getCameraState();
    if (currentZoom != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          zoom: (currentZoom.zoom - 1).clamp(0, 22),
        ),
      );
    }
  }

  void _goToDefaultLocation() {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_defaultLng, _defaultLat)),
        zoom: _defaultZoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  /// Toggle 3D buildings mode
  void _toggle3DMode() async {
    setState(() {
      _is3DMode = !_is3DMode;
    });

    debugPrint('🏗️ SearchPage: ${_is3DMode ? "Enabling" : "Disabling"} 3D mode');

    if (_is3DMode) {
      // Tilt camera for 3D effect
      await _mapboxMap?.setCamera(
        CameraOptions(pitch: 45.0),
      );
    } else {
      // Reset to flat view
      await _mapboxMap?.setCamera(
        CameraOptions(pitch: 0.0),
      );
    }

    HapticFeedback.lightImpact();
  }

  /// Toggle POI layer visibility
  void _togglePOIs() async {
    setState(() {
      _showPOIs = !_showPOIs;
    });

    debugPrint('📍 SearchPage: ${_showPOIs ? "Showing" : "Hiding"} POI layer');

    if (_showPOIs) {
      await _addPOILayer();
    } else {
      // Remove POI layer
      try {
        await _mapboxMap?.style.removeStyleLayer('poi-layer');
        await _mapboxMap?.style.removeStyleSource('poi-source');
      } catch (e) {
        debugPrint('⚠️ SearchPage: Could not remove POI layer - $e');
      }
    }

    HapticFeedback.lightImpact();
  }

  /// Add POI (Points of Interest) layer for campus facilities
  Future<void> _addPOILayer() async {
    try {
      debugPrint('🏢 SearchPage: Adding POI layer...');

      // Campus POIs with emoji icons
      final pois = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "properties": {"icon": "🍽️", "name": "Main Cafeteria"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9235, 5.0410]
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "☕", "name": "Coffee Shop"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9240, 5.0408]
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "🚻", "name": "Restrooms"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9238, 5.0412]
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "🏧", "name": "ATM"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9233, 5.0415]
            }
          },
          {
            "type": "Feature",
            "properties": {"icon": "🅿️", "name": "Parking"},
            "geometry": {
              "type": "Point",
              "coordinates": [7.9245, 5.0405]
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
          textAnchor: TextAnchor.CENTER,
        ),
      );

      debugPrint('✅ SearchPage: POI layer added successfully');
    } catch (e) {
      debugPrint('❌ SearchPage: Failed to add POI layer - $e');
    }
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

    debugPrint('🗺️ SearchPage: Map created, waiting for style to load...');

    // Wait a bit for style to load before adding layers
    await Future.delayed(const Duration(milliseconds: 500));

    // Load map style and add GeoJSON layers
    _setupMap();
  }

  Future<void> _enableLocationTracking() async {
    try {
      debugPrint('📍 SearchPage: Enabling location tracking...');

      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: AppColors.primary.value,
          pulsingMaxRadius: 20.0,
          showAccuracyRing: true,
          accuracyRingColor: AppColors.primary.withOpacity(0.2).value,
          accuracyRingBorderColor: AppColors.primary.withOpacity(0.4).value,
        ),
      );

      debugPrint('✅ SearchPage: Location tracking enabled');
    } catch (e) {
      debugPrint('❌ SearchPage: Failed to enable location tracking - $e');
    }
  }

  Future<void> _setupMap() async {
    try {
      debugPrint('🗺️ SearchPage: Loading GeoJSON files from assets...');
      // Load GeoJSON files from assets
      final buildingsJson = await rootBundle.loadString('assets/geojson/Buildings111.geojson');
      debugPrint('✅ SearchPage: Buildings GeoJSON loaded (${buildingsJson.length} chars)');
      final roadsJson = await rootBundle.loadString('assets/geojson/Roads111.geojson');
      debugPrint('✅ SearchPage: Roads GeoJSON loaded (${roadsJson.length} chars)');

      // Transform GeoJSON from UTM to WGS84
      debugPrint('🔄 SearchPage: Transforming coordinates from UTM to WGS84...');
      final transformedBuildingsJson = await _transformGeoJson(buildingsJson);
      debugPrint('✅ SearchPage: Buildings coordinates transformed');
      final transformedRoadsJson = await _transformGeoJson(roadsJson);
      debugPrint('✅ SearchPage: Roads coordinates transformed');

      // Add GeoJSON sources
      debugPrint('📍 SearchPage: Adding GeoJSON sources to map...');
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "buildings-source",
          data: transformedBuildingsJson,
          cluster: false, // No clustering - keeps MultiPolygon geometry for fills
        ),
      );
      debugPrint('✅ SearchPage: Buildings polygon source added');

      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "roads-source",
          data: transformedRoadsJson,
        ),
      );
      debugPrint('✅ SearchPage: Roads source added');

      // Add color-coded fill layers for buildings (UOB-style)
      debugPrint('🎨 SearchPage: Adding color-coded building layers...');

      // Default - Light tan/beige for ALL buildings (base layer)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-default-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFBCAAA4).value, // Light tan/beige
          fillOpacity: 0.7,
        ),
      );

      // Academic buildings (Classrooms + Laboratory) - Red (rendered on top)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-academic-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFD32F2F).value,
          fillOpacity: 0.75,
          filter: <Object>[
            "match",
            <String>["get", "building_function"],
            <Object>["Classrooms", "Laboratory"],
            true,
            false
          ],
        ),
      );

      // Administrative - Orange
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-admin-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFEF6C00).value,
          fillOpacity: 0.75,
          filter: <Object>[
            "==",
            <String>["get", "building_function"],
            "Admin Block"
          ],
        ),
      );

      // Libraries - Deep Purple
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-library-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFF512DA8).value,
          fillOpacity: 0.75,
          filter: <Object>[
            "==",
            <String>["get", "building_function"],
            "Library"
          ],
        ),
      );

      // Medical - Pink
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "buildings-medical-layer",
          sourceId: "buildings-source",
          fillColor: const Color(0xFFC2185B).value,
          fillOpacity: 0.75,
          filter: <Object>[
            "==",
            <String>["get", "building_function"],
            "Medical Facilities"
          ],
        ),
      );

      debugPrint('✅ SearchPage: Color-coded building layers added');

      // Outline layer
      try {
        await _mapboxMap?.style.addLayer(
          LineLayer(
            id: "buildings-outline-layer",
            sourceId: "buildings-source",
            lineColor: const Color(0xFF616161).value,
            lineOpacity: 0.6,
            lineWidth: 1.0,
          ),
        );
        debugPrint('✅ SearchPage: Buildings outline layer added');
      } catch (e) {
        debugPrint('❌ SearchPage: Failed to add outline layer - $e');
      }

      // Building labels
      try {
        await _mapboxMap?.style.addLayer(
          SymbolLayer(
            id: "buildings-labels-layer",
            sourceId: "buildings-source",
            textField: "{names}",
            textSize: 11.0,
            textColor: const Color(0xFF263238).value,
            textHaloColor: Colors.white.value,
            textHaloWidth: 2.0,
            textHaloBlur: 1.0,
            textAllowOverlap: false,
            textOptional: true,
            textAnchor: TextAnchor.CENTER,
            minZoom: 15.5,
          ),
        );
        debugPrint('✅ SearchPage: Building labels layer added');
      } catch (e) {
        debugPrint('❌ SearchPage: Failed to add labels layer - $e');
      }

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
      debugPrint('✅ SearchPage: Roads line layer added');

      setState(() {
        _mapReady = true;
      });
      debugPrint('🎉 SearchPage: Map setup complete! Buildings and roads visible.');

      // Handle initial building if provided from Campus Info page
      if (!_hasHandledInitialBuilding && widget.initialBuildingName != null) {
        _hasHandledInitialBuilding = true;
        debugPrint('🏢 SearchPage: Showing initial building: ${widget.initialBuildingName}');
        await _onBuildingSelected(widget.initialBuildingName!);
      }
    } catch (e) {
      debugPrint('❌ SearchPage ERROR: Failed to setup map - $e');
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
    debugPrint('👆 SearchPage: Map tapped at position ${context.touchPosition}');
    // Query for buildings at tap location - check all building fill layers
    final features = await _mapboxMap?.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
      RenderedQueryOptions(layerIds: [
        "buildings-default-layer",  // Base layer for all buildings
        "buildings-academic-layer",
        "buildings-admin-layer",
        "buildings-library-layer",
        "buildings-medical-layer",
      ]),
    );

    debugPrint('🔍 SearchPage: Found ${features?.length ?? 0} features at tap location');
    if (features != null && features.isNotEmpty) {
      final feature = features.first;
      // Access properties through queriedFeature.feature
      final featureData = feature?.queriedFeature.feature;
      final propertiesRaw = featureData?['properties'];
      final properties = propertiesRaw != null
          ? Map<String, dynamic>.from(propertiesRaw as Map)
          : null;
      final buildingName = properties?['names'] as String? ?? 'Unknown Building';

      debugPrint('🏢 SearchPage: Tapped on building: $buildingName');

      // Fly to building and show info card (like Android app)
      await _onBuildingSelected(buildingName);
    } else {
      debugPrint('ℹ️ SearchPage: No building found at tap location');
      // Clear selection if tapped on empty area
      if (_selectedBuilding != null) {
        setState(() {
          _selectedBuilding = null;
          _bubblePosition = null;
        });
      }
    }
  }

  Future<void> _onBuildingSelected(String buildingName) async {
    debugPrint('🔎 SearchPage: Building selected: $buildingName');

    // Extract building code if display name format (e.g., "B11 - Library" -> "B11")
    final buildingCode = buildingName.contains(' - ')
        ? buildingName.split(' - ').first
        : buildingName;
    debugPrint('📝 SearchPage: Extracted building code: $buildingCode');

    final buildings = await ref.read(buildingsProvider.future);
    debugPrint('📋 SearchPage: Total buildings available: ${buildings.length}');
    final building = buildings.firstWhere(
      (b) => b.name == buildingCode,
      orElse: () => buildings.first,
    );
    debugPrint('✅ SearchPage: Found building: ${building.name} (${building.buildingFunction})');

    // Use display name for UI (search bar and recent searches)
    final displayName = building.displayName;

    // Update search bar text with display name (like Android app at line 244)
    if (_autocompleteController != null) {
      _autocompleteController!.text = displayName;
      debugPrint('✏️ SearchPage: Updated search bar text to: $displayName');
    }

    // Save display name to recent searches
    await ref.read(recentSearchesServiceProvider).saveSearch(displayName);

    // Get centroid and transform to WGS84
    final centroid = building.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );

    // Fly to building
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(wgs84.longitude, wgs84.latitude)),
        zoom: AppDimensions.mapZoomBuilding, // 16.0
      ),
      MapAnimationOptions(duration: 1000),
    );

    // Wait for camera animation to complete before showing bubble
    await Future.delayed(const Duration(milliseconds: 1100));

    _showBuildingOnMap(buildingCode);
  }

  /// Show building info card on map (like Android app)
  Future<void> _showBuildingOnMap(String buildingName) async {
    try {
      final buildings = await ref.read(buildingsProvider.future);
      final building = buildings.firstWhere(
        (b) => b.name == buildingName,
        orElse: () => buildings.first,
      );

      if (mounted) {
        await _updateBubblePosition(building);
        setState(() {
          _selectedBuilding = building;
        });
      }
    } catch (e) {
      debugPrint('❌ SearchPage: Error showing building info - $e');
    }
  }

  /// Calculate and update bubble position to point at building
  Future<void> _updateBubblePosition(Building building) async {
    final centroid = building.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );

    // Retry getting screen coordinates if map isn't ready yet
    ScreenCoordinate? screenCoord;
    int retries = 0;
    while (screenCoord == null || (screenCoord.x == -1 && screenCoord.y == -1)) {
      if (retries > 10) {
        debugPrint('⚠️ SearchPage: Failed to get valid screen coordinates after 10 retries');
        break;
      }

      await Future.delayed(Duration(milliseconds: retries == 0 ? 0 : 200));
      screenCoord = await _mapboxMap?.pixelForCoordinate(
        Point(coordinates: Position(wgs84.longitude, wgs84.latitude)),
      );

      if (screenCoord != null && screenCoord.x == -1 && screenCoord.y == -1) {
        debugPrint('🔄 SearchPage: Got invalid coordinates (-1, -1), retrying... (attempt ${retries + 1})');
        retries++;
      }
    }

    if (screenCoord != null && screenCoord.x != -1 && screenCoord.y != -1 && mounted) {
      final x = screenCoord.x;
      final y = screenCoord.y;
      debugPrint('📍 SearchPage: Building at screen position ($x, $y)');
      setState(() {
        // Store the exact screen position where the building center is
        _bubblePosition = Offset(x, y);
      });
      debugPrint('✅ SearchPage: Bubble pointer will point to x=$x');
    } else {
      debugPrint('⚠️ SearchPage: Could not get valid screen coordinates for building');
    }
  }


  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showReminderPicker(String buildingName) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((time) {
      if (time != null) {
        // TODO: Schedule notification using flutter_local_notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for $buildingName at ${time.format(context)}'),
          ),
        );
      }
    });
  }
}

/// Custom painter for info box with pointer tab (speech bubble style)
class _InfoBoxWithPointerPainter extends CustomPainter {
  final double pointerX;

  const _InfoBoxWithPointerPainter({required this.pointerX});

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B).withOpacity(0.95)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true; // Smooth edges

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true; // Smooth edges

    const pointerWidth = 24.0;
    const pointerHeight = 14.0;
    final pointerLeft = pointerX.clamp(pointerWidth / 2, size.width - pointerWidth / 2);
    const radius = 8.0;

    final path = Path();

    // Start from left side of pointer base
    path.moveTo(pointerLeft - pointerWidth / 2, pointerHeight);

    // Draw pointer triangle (pointing UP)
    path.lineTo(pointerLeft, 0); // Tip
    path.lineTo(pointerLeft + pointerWidth / 2, pointerHeight); // Right base

    // Top right corner
    path.lineTo(size.width - radius, pointerHeight);
    path.quadraticBezierTo(
      size.width, pointerHeight,
      size.width, pointerHeight + radius,
    );

    // Right edge
    path.lineTo(size.width, size.height - radius);

    // Bottom right corner
    path.quadraticBezierTo(
      size.width, size.height,
      size.width - radius, size.height,
    );

    // Bottom edge
    path.lineTo(radius, size.height);

    // Bottom left corner
    path.quadraticBezierTo(
      0, size.height,
      0, size.height - radius,
    );

    // Left edge
    path.lineTo(0, pointerHeight + radius);

    // Top left corner
    path.quadraticBezierTo(
      0, pointerHeight,
      radius, pointerHeight,
    );

    // Complete top edge to pointer
    path.lineTo(pointerLeft - pointerWidth / 2, pointerHeight);

    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.3), 4.0, false);

    // Draw filled shape
    canvas.drawPath(path, paint);

    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _InfoBoxWithPointerPainter oldDelegate) {
    return oldDelegate.pointerX != pointerX;
  }
}
