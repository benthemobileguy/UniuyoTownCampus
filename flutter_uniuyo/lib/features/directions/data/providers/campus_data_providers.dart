import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/road.dart';
import '../../domain/repositories/campus_data_repository.dart';
import '../datasources/geojson_local_datasource.dart';
import '../repositories/campus_data_repository_impl.dart';

part 'campus_data_providers.g.dart';

/// Provider for GeoJSON data source
@riverpod
GeoJsonLocalDataSource geoJsonDataSource(GeoJsonDataSourceRef ref) {
  debugPrint('🔧 Provider: Creating GeoJsonLocalDataSource');
  return GeoJsonLocalDataSource();
}

/// Provider for campus data repository
@riverpod
CampusDataRepository campusDataRepository(CampusDataRepositoryRef ref) {
  debugPrint('🔧 Provider: Creating CampusDataRepository');
  final dataSource = ref.watch(geoJsonDataSourceProvider);
  return CampusDataRepositoryImpl(dataSource);
}

/// Provider for all buildings
@riverpod
Future<List<Building>> buildings(BuildingsRef ref) async {
  debugPrint('📍 Provider: Fetching all buildings...');
  final repository = ref.watch(campusDataRepositoryProvider);
  final buildings = await repository.getBuildings();
  debugPrint('✅ Provider: Fetched ${buildings.length} buildings');
  return buildings;
}

/// Provider for all roads
@riverpod
Future<List<Road>> roads(RoadsRef ref) async {
  debugPrint('🛣️ Provider: Fetching all roads...');
  final repository = ref.watch(campusDataRepositoryProvider);
  final roads = await repository.getRoads();
  debugPrint('✅ Provider: Fetched ${roads.length} roads');
  return roads;
}

/// Provider for building search
@riverpod
Future<List<Building>> searchBuildings(
  SearchBuildingsRef ref,
  String query,
) async {
  debugPrint('🔍 Provider: Searching buildings with query: "$query"');
  final repository = ref.watch(campusDataRepositoryProvider);
  final results = await repository.searchBuildings(query);
  debugPrint('✅ Provider: Search found ${results.length} buildings matching "$query"');
  return results;
}

/// Provider for building names (for autocomplete)
@riverpod
Future<List<String>> buildingNames(BuildingNamesRef ref) async {
  debugPrint('📝 Provider: Loading building names for autocomplete...');
  final buildings = await ref.watch(buildingsProvider.future);
  final names = buildings.map((b) => b.displayName).toList()..sort();
  debugPrint('✅ Provider: Loaded ${names.length} building display names');
  return names;
}
