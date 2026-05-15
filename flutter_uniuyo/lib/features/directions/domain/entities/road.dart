import 'package:freezed_annotation/freezed_annotation.dart';

part 'road.freezed.dart';
part 'road.g.dart';

/// Road entity matching the Roads111.geojson structure
@freezed
class Road with _$Road {
  const factory Road({
    required String name,
    String? source,
    String? target,
    required List<List<List<double>>> coordinates, // MultiLineString coordinates
  }) = _Road;

  factory Road.fromJson(Map<String, dynamic> json) => _$RoadFromJson(json);

  /// Create Road from GeoJSON Feature
  factory Road.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;

    return Road(
      name: properties['Names'] as String? ?? 'Unnamed Road',
      source: properties['source'] as String?,
      target: properties['target'] as String?,
      coordinates: coords
          .map((lineString) => (lineString as List<dynamic>)
              .map((coord) => (coord as List<dynamic>)
                  .map((c) => (c as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );
  }
}
