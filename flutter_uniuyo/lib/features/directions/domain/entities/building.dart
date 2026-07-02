import 'package:freezed_annotation/freezed_annotation.dart';

part 'building.freezed.dart';
part 'building.g.dart';

/// Building entity supporting both old and new GeoJSON formats
/// Old format: gid, names, area_m2, building_function
/// New format: OBJECTID, Name, Category, Shape_Area
@freezed
class Building with _$Building {
  const factory Building({
    required int gid,
    required String name,
    required double areaM2,
    required String buildingFunction,
    required List<List<List<double>>> coordinates, // MultiPolygon coordinates
  }) = _Building;

  factory Building.fromJson(Map<String, dynamic> json) =>
      _$BuildingFromJson(json);

  /// Create Building from GeoJSON Feature
  /// Supports both old format (gid/names/area_m2/building_function)
  /// and new format (OBJECTID/Name/Category/Shape_Area)
  factory Building.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;

    // Support both old and new property names
    final gid = (properties['gid'] ?? properties['OBJECTID'] ?? 0) as int;
    final name = (properties['names'] ?? properties['Name'] ?? 'Unknown') as String;
    final areaM2 = ((properties['area_m2'] ?? properties['Shape_Area'] ?? 0.0) as num).toDouble();
    final buildingFunction = (properties['building_function'] ?? properties['Category'] ?? 'Unknown') as String;

    return Building(
      gid: gid,
      name: name,
      areaM2: areaM2,
      buildingFunction: buildingFunction,
      coordinates: coords
          .map((polygon) => (polygon as List<dynamic>)
              .map((ring) => (ring as List<dynamic>)
                  .expand((coord) {
                    // coord is [x, y], flatten to [x, y] in the list
                    final coordList = coord as List;
                    return [
                      (coordList[0] as num).toDouble(),
                      (coordList[1] as num).toDouble(),
                    ];
                  })
                  .toList())
              .toList())
          .toList(),
    );
  }
}

/// Extension to get center point of building (for display on map)
extension BuildingExtension on Building {
  /// Calculate centroid of the building's first polygon
  /// Coordinates are in UTM EPSG:32632 format
  ({double x, double y}) get centroid {
    if (coordinates.isEmpty || coordinates[0].isEmpty || coordinates[0][0].isEmpty) {
      return (x: 0.0, y: 0.0);
    }

    final ring = coordinates[0][0]; // First ring of first polygon
    double sumX = 0.0;
    double sumY = 0.0;

    for (var i = 0; i < ring.length; i += 2) {
      if (i + 1 < ring.length) {
        sumX += ring[i];
        sumY += ring[i + 1];
      }
    }

    final count = ring.length ~/ 2;
    return count > 0
        ? (x: sumX / count, y: sumY / count)
        : (x: 0.0, y: 0.0);
  }

  /// Get a user-friendly display name
  /// For short names (like "A1", "B11"), combines with function: "B11 - Library"
  /// For descriptive names (like "Central Admin Block"), just shows the name
  String get displayName {
    // If name is short (likely a code like "A1", "B11"), append the function
    if (name.length <= 4 && RegExp(r'^[A-Z]\d+$').hasMatch(name)) {
      return '$name - $buildingFunction';
    }
    // For longer descriptive names, just return the name
    return name;
  }
}
