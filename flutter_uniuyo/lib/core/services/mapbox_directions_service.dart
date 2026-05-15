import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for requesting routes from Mapbox Directions API
/// Mirrors DirectionsActivity.kt route request functionality
class MapboxDirectionsService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  // Access token loaded from environment variable at compile time
  // Build with: flutter run --dart-define=MAPBOX_ACCESS_TOKEN=your_token_here
  // Or define in local.properties for Android builds
  static const String _accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '', // Will be empty if not provided - app will fail gracefully
  );

  /// Request a walking route between two points
  ///
  /// Parameters:
  /// - origin: Starting point [longitude, latitude]
  /// - destination: End point [longitude, latitude]
  ///
  /// Returns DirectionsResponse with route geometry and metadata
  Future<DirectionsResponse?> getWalkingRoute({
    required List<double> origin,
    required List<double> destination,
  }) async {
    try {
      debugPrint('🗺️ MapboxDirectionsService: Requesting walking route...');
      debugPrint('   Origin: $origin');
      debugPrint('   Destination: $destination');

      // Build coordinates string: "lng,lat;lng,lat"
      final coordinates = '${origin[0]},${origin[1]};${destination[0]},${destination[1]}';

      // Build request URL with parameters matching Android RouteOptions
      final url = Uri.parse(
        '$_baseUrl/walking/$coordinates'
        '?geometries=geojson'
        '&overview=full'
        '&steps=true'
        '&alternatives=true' // Request up to 3 alternative routes
        '&access_token=$_accessToken',
      );

      debugPrint('🌐 MapboxDirectionsService: Making API request...');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ MapboxDirectionsService: Route received successfully');

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = DirectionsResponse.fromJson(data);
          debugPrint('📏 Route distance: ${route.distance}m, duration: ${route.duration}s');
          return route;
        } else {
          debugPrint('⚠️ MapboxDirectionsService: No routes found in response');
          return null;
        }
      } else {
        debugPrint('❌ MapboxDirectionsService: API error ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ MapboxDirectionsService ERROR: $e');
      return null;
    }
  }
}

/// Response from Mapbox Directions API
class DirectionsResponse {
  final List<Route> routes;
  final List<Waypoint> waypoints;

  DirectionsResponse({
    required this.routes,
    required this.waypoints,
  });

  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    return DirectionsResponse(
      routes: (json['routes'] as List)
          .map((r) => Route.fromJson(r as Map<String, dynamic>))
          .toList(),
      waypoints: (json['waypoints'] as List)
          .map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  // Get primary route
  Route get primaryRoute => routes.first;

  // Get route distance in meters
  double get distance => primaryRoute.distance;

  // Get route duration in seconds
  double get duration => primaryRoute.duration;

  // Get route geometry as GeoJSON string
  String get geometryGeoJson => json.encode(primaryRoute.geometry);
}

/// A route from the Directions API
class Route {
  final Map<String, dynamic> geometry; // GeoJSON LineString
  final double distance; // meters
  final double duration; // seconds
  final List<RouteLeg> legs;

  Route({
    required this.geometry,
    required this.distance,
    required this.duration,
    required this.legs,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      geometry: json['geometry'] as Map<String, dynamic>,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      legs: (json['legs'] as List)
          .map((l) => RouteLeg.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  // Get route coordinates as List<List<double>> (for LineString)
  List<List<double>> get coordinates {
    final coords = geometry['coordinates'] as List;
    return coords.map((c) => List<double>.from(c as List)).toList();
  }
}

/// A leg of a route (from one waypoint to another)
class RouteLeg {
  final double distance;
  final double duration;
  final List<RouteStep> steps;

  RouteLeg({
    required this.distance,
    required this.duration,
    required this.steps,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    return RouteLeg(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      steps: (json['steps'] as List)
          .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A step in a route leg (turn-by-turn instruction)
class RouteStep {
  final double distance;
  final double duration;
  final String instruction;
  final String? name;

  RouteStep({
    required this.distance,
    required this.duration,
    required this.instruction,
    this.name,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>;
    return RouteStep(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      instruction: maneuver['instruction'] as String? ?? '',
      name: json['name'] as String?,
    );
  }
}

/// A waypoint in the route
class Waypoint {
  final String name;
  final List<double> location; // [lng, lat]

  Waypoint({
    required this.name,
    required this.location,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      name: json['name'] as String? ?? '',
      location: List<double>.from(json['location'] as List),
    );
  }
}
