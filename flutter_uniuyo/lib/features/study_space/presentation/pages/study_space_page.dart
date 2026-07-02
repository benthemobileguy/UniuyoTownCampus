import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/coordinate_transformer.dart';
import '../../../../core/widgets/building_details_sheet.dart';
import '../../../directions/data/providers/campus_data_providers.dart';
import '../../../directions/domain/entities/building.dart';

/// Provider for academic buildings (filtered by Category)
final academicBuildingsProvider = FutureProvider<List<Building>>((ref) async {
  final allBuildings = await ref.watch(buildingsProvider.future);

  // Filter ONLY academic buildings based on new Category values
  // New format: "Academic Unit", "Academic/Adminstrative Unit", etc.
  // EXCLUDED: Pure admin buildings, hostels, parking, sports, construction

  // Categories to include (academic-related)
  final academicCategories = [
    'academic unit',
    'academic uni',
    'academic',
    // Mixed academic/admin buildings are included as they have academic use
    'academic/adminstarative unit',
    'academic/adminstartive unit',
    'academic/adminstative unit',
    'academic/adminstration unit',
    'academic/adminstrative unit',
    'academiic/adminstrative unit',
  ];

  // Categories to exclude (non-academic)
  final excludedCategories = [
    'adminstrative unit',
    'adminstrative',
    'adminstative unit',
    'adminstravive unit',
    'hostel',
    'hostels',
    'parking lot',
    'sports facility',
    'under construction',
    'under-construction',
    'other',
    'others',
  ];

  final academicBuildings = allBuildings.where((building) {
    final category = building.buildingFunction.toLowerCase();

    // Check if it's an excluded category
    if (excludedCategories.any((excluded) => category == excluded)) {
      return false;
    }

    // Include if it matches an academic category
    return academicCategories.any((academic) => category == academic || category.contains('academic'));
  }).toList();

  debugPrint('📚 StudySpace Filter: Found ${academicBuildings.length} academic buildings out of ${allBuildings.length} total');
  for (final building in academicBuildings.take(10)) {
    debugPrint('   ✅ ${building.name} - ${building.buildingFunction}');
  }

  return academicBuildings;
});

/// Study Space page showing academic buildings highlighted
class StudySpacePage extends ConsumerStatefulWidget {
  const StudySpacePage({super.key});

  @override
  ConsumerState<StudySpacePage> createState() => _StudySpacePageState();
}

class _StudySpacePageState extends ConsumerState<StudySpacePage> {
  MapboxMap? _mapboxMap;
  bool _mapReady = false;
  bool _showAcademicList = false;
  bool _is3DMode = false; // 3D buildings toggle
  bool _showPOIs = false; // POI layer toggle

  // From DirectionsActivity.kt line 216, 67-68
  static const double _defaultLat = 5.0409083;
  static const double _defaultLng = 7.9235053;
  static const double _defaultZoom = AppDimensions.mapZoomDefault; // 15.0

  @override
  Widget build(BuildContext context) {
    final academicBuildingsAsync = ref.watch(academicBuildingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("studySpaceMap"),
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTapped,
          ),

          // Header with title and academic count
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: AppColors.colorPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Study Spaces',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.colorPrimary,
                            ),
                          ),
                          academicBuildingsAsync.when(
                            data: (buildings) => Text(
                              '${buildings.length} Academic Buildings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            loading: () => const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 12),
                            ),
                            error: (_, __) => const Text(
                              'Error loading data',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showAcademicList ? Icons.map : Icons.list,
                        color: AppColors.colorPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAcademicList = !_showAcademicList;
                        });
                      },
                      tooltip: _showAcademicList ? 'Show Map' : 'Show List',
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.colorPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Academic Buildings List (overlay when toggled)
          if (_showAcademicList)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: academicBuildingsAsync.when(
                  data: (buildings) => _buildAcademicList(buildings),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ),

          // Map Controls - All icon buttons in one aligned column
          if (!_showAcademicList)
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

          // Legend
          if (!_showAcademicList)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.customGreen.withOpacity(0.7),
                              border: Border.all(color: AppColors.customGreen, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Academic Buildings',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.buildingFillColor.withOpacity(0.3),
                              border: Border.all(color: AppColors.buildingFillColor, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Other Buildings',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcademicList(List<Building> buildings) {
    if (buildings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No academic buildings found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.customGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: AppColors.customGreen),
                const SizedBox(width: 8),
                Text(
                  'Academic Buildings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.customGreen,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: buildings.length,
              itemBuilder: (context, index) {
                final building = buildings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.customGreen,
                      child: const Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      building.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      building.buildingFunction,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.location_on,
                      color: AppColors.customGreen,
                      size: 20,
                    ),
                    onTap: () => _flyToBuilding(building),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _flyToBuilding(Building building) {
    setState(() {
      _showAcademicList = false;
    });

    final centroid = building.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );

    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(wgs84.longitude, wgs84.latitude)),
        zoom: AppDimensions.mapZoomBuilding, // 16.0
      ),
      MapAnimationOptions(duration: 1000),
    );

    // Show building info
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        _showBuildingDialog(building.name, building.buildingFunction);
      }
    });
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

    debugPrint('🏗️ StudySpacePage: ${_is3DMode ? "Enabling" : "Disabling"} 3D mode');

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

    debugPrint('📍 StudySpacePage: ${_showPOIs ? "Showing" : "Hiding"} POI layer');

    if (_showPOIs) {
      await _addPOILayer();
    } else {
      // Remove POI layer
      try {
        await _mapboxMap?.style.removeStyleLayer('poi-layer');
        await _mapboxMap?.style.removeStyleSource('poi-source');
      } catch (e) {
        debugPrint('⚠️ StudySpacePage: Could not remove POI layer - $e');
      }
    }

    HapticFeedback.lightImpact();
  }

  /// Add POI (Points of Interest) layer for campus facilities
  Future<void> _addPOILayer() async {
    try {
      debugPrint('🏢 StudySpacePage: Adding POI layer...');

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

      debugPrint('✅ StudySpacePage: POI layer added successfully');
    } catch (e) {
      debugPrint('❌ StudySpacePage: Failed to add POI layer - $e');
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

    debugPrint('🗺️ StudySpacePage: Map created, waiting for style to load...');

    // Wait a bit for style to load before adding layers
    await Future.delayed(const Duration(milliseconds: 500));

    // Load map style and add GeoJSON layers
    _setupMap();
  }

  Future<void> _enableLocationTracking() async {
    try {
      debugPrint('📍 StudySpacePage: Enabling location tracking...');

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

      debugPrint('✅ StudySpacePage: Location tracking enabled');
    } catch (e) {
      debugPrint('❌ StudySpacePage: Failed to enable location tracking - $e');
    }
  }

  Future<void> _setupMap() async {
    try {
      debugPrint('🗺️ StudySpacePage: Loading GeoJSON files from assets...');
      // Load GeoJSON files from assets
      final buildingsJson = await rootBundle.loadString('assets/geojson/Buildings111.geojson');
      debugPrint('✅ StudySpacePage: Buildings GeoJSON loaded');
      final roadsJson = await rootBundle.loadString('assets/geojson/Roads111.geojson');
      debugPrint('✅ StudySpacePage: Roads GeoJSON loaded');

      // Get academic buildings for filtering
      final academicBuildings = await ref.read(academicBuildingsProvider.future);
      final academicGids = academicBuildings.map((b) => b.gid).toSet();
      debugPrint('📚 StudySpacePage: Found ${academicBuildings.length} academic buildings');

      // Transform GeoJSON and separate academic buildings
      debugPrint('🔄 StudySpacePage: Transforming coordinates...');
      final buildingsGeoJson = json.decode(buildingsJson) as Map<String, dynamic>;
      final features = buildingsGeoJson['features'] as List<dynamic>;

      // Split features into academic and non-academic
      final academicFeatures = <dynamic>[];
      final otherFeatures = <dynamic>[];

      for (var feature in features) {
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final type = geometry['type'] as String;
        final coords = geometry['coordinates'];

        // Transform coordinates
        if (type == 'MultiPolygon') {
          geometry['coordinates'] = _transformMultiPolygon(coords);
        }

        // Check if academic building (support both old 'gid' and new 'OBJECTID')
        final propertiesRaw = feature['properties'];
        final properties = Map<String, dynamic>.from(propertiesRaw as Map);
        final gid = (properties['gid'] ?? properties['OBJECTID'] ?? 0) as int;

        if (academicGids.contains(gid)) {
          academicFeatures.add(feature);
        } else {
          otherFeatures.add(feature);
        }
      }

      debugPrint('✅ StudySpacePage: Separated ${academicFeatures.length} academic, ${otherFeatures.length} other buildings');

      // Transform roads
      final transformedRoadsJson = await _transformGeoJson(roadsJson);

      // Create separate GeoJSON for academic and other buildings
      final academicGeoJson = json.encode({
        'type': 'FeatureCollection',
        'features': academicFeatures,
      });

      final otherGeoJson = json.encode({
        'type': 'FeatureCollection',
        'features': otherFeatures,
      });

      // Add GeoJSON sources
      debugPrint('📍 StudySpacePage: Adding map sources...');
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "academic-buildings-source",
          data: academicGeoJson,
          cluster: false, // No clustering - keeps MultiPolygon geometry
        ),
      );

      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "other-buildings-source",
          data: otherGeoJson,
          cluster: false, // No clustering - keeps MultiPolygon geometry
        ),
      );

      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "roads-source",
          data: transformedRoadsJson,
        ),
      );
      debugPrint('✅ StudySpacePage: Sources added');

      // Add building fill layers
      debugPrint('🎨 StudySpacePage: Adding map layers...');

      // Other buildings fill (dimmed)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "other-buildings-layer",
          sourceId: "other-buildings-source",
          fillColor: AppColors.buildingFillColor.value,
          fillOpacity: 0.3, // Dimmed
        ),
      );

      // Academic buildings fill (highlighted)
      await _mapboxMap?.style.addLayer(
        FillLayer(
          id: "academic-buildings-layer",
          sourceId: "academic-buildings-source",
          fillColor: AppColors.customGreen.value,
          fillOpacity: 0.7, // Highlighted
        ),
      );

      // Building outlines
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "academic-buildings-outline",
          sourceId: "academic-buildings-source",
          lineColor: AppColors.customGreen.value,
          lineOpacity: 0.9,
          lineWidth: 2.0,
        ),
      );

      // Building labels
      await _mapboxMap?.style.addLayer(
        SymbolLayer(
          id: "academic-buildings-labels",
          sourceId: "academic-buildings-source",
          textField: "{Name}",
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

      // Add roads
      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "roads-line-layer",
          sourceId: "roads-source",
          lineColor: AppColors.roadColor.value,
          lineOpacity: AppColors.roadOpacity,
          lineWidth: 2.0,
        ),
      );
      debugPrint('✅ StudySpacePage: Layers added');

      setState(() {
        _mapReady = true;
      });
      debugPrint('🎉 StudySpacePage: Map setup complete! Academic buildings highlighted in green.');
    } catch (e) {
      debugPrint('❌ StudySpacePage ERROR: Failed to setup map - $e');
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
    debugPrint('👆 StudySpacePage: Map tapped');
    // Query for academic buildings at tap location
    final features = await _mapboxMap?.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
      RenderedQueryOptions(layerIds: ["academic-buildings-layer"]),
    );

    if (features != null && features.isNotEmpty) {
      final feature = features.first;
      final featureData = feature?.queriedFeature.feature;
      final propertiesRaw = featureData?['properties'];
      final properties = propertiesRaw != null
          ? Map<String, dynamic>.from(propertiesRaw as Map)
          : null;
      final buildingName = properties?['Name'] as String? ?? 'Unknown Building';
      final buildingFunction = properties?['Category'] as String? ?? 'Unknown';

      debugPrint('🏢 StudySpacePage: Tapped on academic building: $buildingName');
      _showBuildingDialog(buildingName, buildingFunction);
    }
  }

  Future<void> _showBuildingDialog(String buildingName, String buildingFunction) async {
    try {
      final buildings = await ref.read(buildingsProvider.future);
      final building = buildings.firstWhere(
        (b) => b.name == buildingName,
        orElse: () => buildings.first,
      );

      if (mounted) {
        BuildingDetailsSheet.show(
          context,
          building: building,
          onGetDirections: () {
            // TODO: Navigate to DirectionsPage with this building as destination
            debugPrint('📍 Get directions to: ${building.name}');
          },
          onSetReminder: () {
            // TODO: Set reminder for study session
            debugPrint('⏰ Set reminder for: ${building.name}');
          },
        );
      }
    } catch (e) {
      debugPrint('❌ StudySpacePage: Error showing building info - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load building details')),
        );
      }
    }
  }
}
