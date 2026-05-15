import 'dart:math' as math;

/// Utility class to transform coordinates from UTM EPSG:32632 to WGS84 (lat/lng)
///
/// EPSG:32632 is UTM Zone 32N, used in the GeoJSON files.
/// Mapbox requires WGS84 coordinates (latitude, longitude).
class CoordinateTransformer {
  // WGS84 ellipsoid parameters
  static const double _a = 6378137.0; // Semi-major axis (meters)
  static const double _e = 0.0818191908426; // First eccentricity
  static const double _e2 = 0.00669437999014; // e squared

  // UTM Zone 32N parameters
  static const int _zone = 32;
  static const double _k0 = 0.9996; // Scale factor
  static const double _e0 = 500000.0; // False easting
  static const double _n0 = 0.0; // False northing (0 for northern hemisphere)

  /// Transform UTM EPSG:32632 coordinates to WGS84 (lat/lng)
  ///
  /// [easting] - X coordinate in UTM (meters)
  /// [northing] - Y coordinate in UTM (meters)
  ///
  /// Returns a record with latitude and longitude in decimal degrees
  static ({double latitude, double longitude}) utmToWgs84({
    required double easting,
    required double northing,
  }) {
    final x = easting - _e0;
    final y = northing - _n0;

    final m = y / _k0;
    final mu = m / (_a * (1 - _e2 / 4 - 3 * _e2 * _e2 / 64 - 5 * _e2 * _e2 * _e2 / 256));

    final e1 = (1 - math.sqrt(1 - _e2)) / (1 + math.sqrt(1 - _e2));

    final phi1 = mu +
        (3 * e1 / 2 - 27 * e1 * e1 * e1 / 32) * math.sin(2 * mu) +
        (21 * e1 * e1 / 16 - 55 * e1 * e1 * e1 * e1 / 32) * math.sin(4 * mu) +
        (151 * e1 * e1 * e1 / 96) * math.sin(6 * mu);

    final n = _a / math.sqrt(1 - _e2 * math.sin(phi1) * math.sin(phi1));
    final t = math.tan(phi1) * math.tan(phi1);
    final c = _e2 * math.cos(phi1) * math.cos(phi1) / (1 - _e2);
    final r = _a * (1 - _e2) / math.pow(1 - _e2 * math.sin(phi1) * math.sin(phi1), 1.5);
    final d = x / (n * _k0);

    var latitude = phi1 -
        (n * math.tan(phi1) / r) *
        (d * d / 2 -
         (5 + 3 * t + 10 * c - 4 * c * c - 9 * _e2) * d * d * d * d / 24 +
         (61 + 90 * t + 298 * c + 45 * t * t - 252 * _e2 - 3 * c * c) * d * d * d * d * d * d / 720);

    var longitude =
        (d - (1 + 2 * t + c) * d * d * d / 6 +
         (5 - 2 * c + 28 * t - 3 * c * c + 8 * _e2 + 24 * t * t) * d * d * d * d * d / 120) /
        math.cos(phi1);

    // Convert from radians to degrees
    latitude = latitude * 180.0 / math.pi;

    // Central meridian for Zone 32
    final centralMeridian = (_zone - 1) * 6 - 180 + 3;
    longitude = centralMeridian + longitude * 180.0 / math.pi;

    return (latitude: latitude, longitude: longitude);
  }

  /// Transform a list of UTM coordinates to WGS84
  static List<({double latitude, double longitude})> transformCoordinateList(
    List<List<double>> utmCoords,
  ) {
    return utmCoords.map((coord) {
      if (coord.length >= 2) {
        return utmToWgs84(easting: coord[0], northing: coord[1]);
      }
      return (latitude: 0.0, longitude: 0.0);
    }).toList();
  }
}
