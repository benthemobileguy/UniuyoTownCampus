import 'package:freezed_annotation/freezed_annotation.dart';

part 'building.freezed.dart';
part 'building.g.dart';

/// Building entity matching the Buildings111.geojson structure
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
  factory Building.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;

    return Building(
      gid: properties['gid'] as int,
      name: properties['names'] as String? ?? 'Unknown',
      areaM2: (properties['area_m2'] as num?)?.toDouble() ?? 0.0,
      buildingFunction: properties['building_function'] as String? ?? 'Unknown',
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

  /// Get a user-friendly display name combining code and function
  /// Example: "B11 - Library" or "A1 - Laboratory"
  String get displayName {
    return '$name - $buildingFunction';
  }
}
