import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/road.dart';

/// Local data source for loading GeoJSON files from assets
class GeoJsonLocalDataSource {
  static const String _buildingsPath = 'assets/geojson/Buildings111.geojson';
  static const String _roadsPath = 'assets/geojson/Roads111.geojson';

  /// Load and parse Buildings111.geojson
  Future<List<Building>> loadBuildings() async {
    try {
      debugPrint('📂 GeoJsonDataSource: Loading buildings from $_buildingsPath');
      final jsonString = await rootBundle.loadString(_buildingsPath);
      debugPrint('✅ GeoJsonDataSource: Buildings file loaded (${jsonString.length} chars)');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final features = jsonData['features'] as List<dynamic>?;
      if (features == null) {
        debugPrint('⚠️ GeoJsonDataSource: No features found in buildings GeoJSON');
        return [];
      }

      final buildings = features
          .map((feature) => Building.fromGeoJsonFeature(feature as Map<String, dynamic>))
          .toList();
      debugPrint('🏢 GeoJsonDataSource: Loaded ${buildings.length} buildings');
      debugPrint('📋 GeoJsonDataSource: Sample buildings: ${buildings.take(3).map((b) => b.name).join(", ")}');
      return buildings;
    } catch (e) {
      debugPrint('❌ GeoJsonDataSource ERROR: Failed to load buildings - $e');
      throw Exception('Failed to load buildings: $e');
    }
  }

  /// Load and parse Roads111.geojson
  Future<List<Road>> loadRoads() async {
    try {
      final jsonString = await rootBundle.loadString(_roadsPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      final features = jsonData['features'] as List<dynamic>?;
      if (features == null) {
        return [];
      }

      return features
          .map((feature) => Road.fromGeoJsonFeature(feature as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load roads: $e');
    }
  }

  /// Load both buildings and roads
  Future<({List<Building> buildings, List<Road> roads})> loadAll() async {
    final results = await Future.wait([
      loadBuildings(),
      loadRoads(),
    ]);

    return (
      buildings: results[0] as List<Building>,
      roads: results[1] as List<Road>,
    );
  }
}
