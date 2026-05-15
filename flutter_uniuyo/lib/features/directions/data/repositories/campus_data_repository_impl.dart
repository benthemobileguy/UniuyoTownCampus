import '../../domain/entities/building.dart';
import '../../domain/entities/road.dart';
import '../../domain/repositories/campus_data_repository.dart';
import '../datasources/geojson_local_datasource.dart';

/// Implementation of CampusDataRepository using local GeoJSON files
class CampusDataRepositoryImpl implements CampusDataRepository {
  final GeoJsonLocalDataSource _dataSource;

  // Cache for loaded data
  List<Building>? _cachedBuildings;
  List<Road>? _cachedRoads;

  CampusDataRepositoryImpl(this._dataSource);

  @override
  Future<List<Building>> getBuildings() async {
    // Return cached data if available
    if (_cachedBuildings != null) {
      return _cachedBuildings!;
    }

    // Load from data source
    _cachedBuildings = await _dataSource.loadBuildings();
    return _cachedBuildings!;
  }

  @override
  Future<List<Road>> getRoads() async {
    // Return cached data if available
    if (_cachedRoads != null) {
      return _cachedRoads!;
    }

    // Load from data source
    _cachedRoads = await _dataSource.loadRoads();
    return _cachedRoads!;
  }

  @override
  Future<List<Building>> searchBuildings(String query) async {
    final buildings = await getBuildings();

    if (query.isEmpty) {
      return buildings;
    }

    final lowerQuery = query.toLowerCase();
    return buildings.where((building) {
      return building.name.toLowerCase().contains(lowerQuery) ||
             building.buildingFunction.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<Building?> getBuildingByName(String name) async {
    final buildings = await getBuildings();

    try {
      return buildings.firstWhere(
        (building) => building.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear cache to force reload
  void clearCache() {
    _cachedBuildings = null;
    _cachedRoads = null;
  }
}
