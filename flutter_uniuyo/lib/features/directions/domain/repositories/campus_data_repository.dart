import '../entities/building.dart';
import '../entities/road.dart';

/// Repository interface for campus data (buildings and roads)
abstract class CampusDataRepository {
  /// Get all buildings from GeoJSON
  Future<List<Building>> getBuildings();

  /// Get all roads from GeoJSON
  Future<List<Road>> getRoads();

  /// Search buildings by name
  Future<List<Building>> searchBuildings(String query);

  /// Get building by exact name
  Future<Building?> getBuildingByName(String name);
}
