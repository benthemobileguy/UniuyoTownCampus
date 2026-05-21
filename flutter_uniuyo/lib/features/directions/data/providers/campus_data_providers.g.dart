// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campus_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$geoJsonDataSourceHash() => r'47c644191489c34a777e0ba01504b8aa861225d7';

/// Provider for GeoJSON data source
///
/// Copied from [geoJsonDataSource].
@ProviderFor(geoJsonDataSource)
final geoJsonDataSourceProvider =
    AutoDisposeProvider<GeoJsonLocalDataSource>.internal(
  geoJsonDataSource,
  name: r'geoJsonDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geoJsonDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeoJsonDataSourceRef = AutoDisposeProviderRef<GeoJsonLocalDataSource>;
String _$campusDataRepositoryHash() =>
    r'40f38eb035c6791698ee1cbe8ec8426bcd09f874';

/// Provider for campus data repository
///
/// Copied from [campusDataRepository].
@ProviderFor(campusDataRepository)
final campusDataRepositoryProvider =
    AutoDisposeProvider<CampusDataRepository>.internal(
  campusDataRepository,
  name: r'campusDataRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$campusDataRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CampusDataRepositoryRef = AutoDisposeProviderRef<CampusDataRepository>;
String _$buildingsHash() => r'a015cf73334a3415db27e952517c49717686e221';

/// Provider for all buildings
///
/// Copied from [buildings].
@ProviderFor(buildings)
final buildingsProvider = AutoDisposeFutureProvider<List<Building>>.internal(
  buildings,
  name: r'buildingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$buildingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BuildingsRef = AutoDisposeFutureProviderRef<List<Building>>;
String _$roadsHash() => r'7f747a64c9dfedb22a224643a345405b1f78ddc1';

/// Provider for all roads
///
/// Copied from [roads].
@ProviderFor(roads)
final roadsProvider = AutoDisposeFutureProvider<List<Road>>.internal(
  roads,
  name: r'roadsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$roadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoadsRef = AutoDisposeFutureProviderRef<List<Road>>;
String _$searchBuildingsHash() => r'62f688f678cc2e8bb8ab6aad4553f46b28b9a7f9';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for building search
///
/// Copied from [searchBuildings].
@ProviderFor(searchBuildings)
const searchBuildingsProvider = SearchBuildingsFamily();

/// Provider for building search
///
/// Copied from [searchBuildings].
class SearchBuildingsFamily extends Family<AsyncValue<List<Building>>> {
  /// Provider for building search
  ///
  /// Copied from [searchBuildings].
  const SearchBuildingsFamily();

  /// Provider for building search
  ///
  /// Copied from [searchBuildings].
  SearchBuildingsProvider call(
    String query,
  ) {
    return SearchBuildingsProvider(
      query,
    );
  }

  @override
  SearchBuildingsProvider getProviderOverride(
    covariant SearchBuildingsProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchBuildingsProvider';
}

/// Provider for building search
///
/// Copied from [searchBuildings].
class SearchBuildingsProvider
    extends AutoDisposeFutureProvider<List<Building>> {
  /// Provider for building search
  ///
  /// Copied from [searchBuildings].
  SearchBuildingsProvider(
    String query,
  ) : this._internal(
          (ref) => searchBuildings(
            ref as SearchBuildingsRef,
            query,
          ),
          from: searchBuildingsProvider,
          name: r'searchBuildingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchBuildingsHash,
          dependencies: SearchBuildingsFamily._dependencies,
          allTransitiveDependencies:
              SearchBuildingsFamily._allTransitiveDependencies,
          query: query,
        );

  SearchBuildingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Building>> Function(SearchBuildingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchBuildingsProvider._internal(
        (ref) => create(ref as SearchBuildingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Building>> createElement() {
    return _SearchBuildingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchBuildingsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchBuildingsRef on AutoDisposeFutureProviderRef<List<Building>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchBuildingsProviderElement
    extends AutoDisposeFutureProviderElement<List<Building>>
    with SearchBuildingsRef {
  _SearchBuildingsProviderElement(super.provider);

  @override
  String get query => (origin as SearchBuildingsProvider).query;
}

String _$buildingNamesHash() => r'a66edaf6f7db180b72716ad80f4ba195bcb4d4d2';

/// Provider for building names (for autocomplete)
///
/// Copied from [buildingNames].
@ProviderFor(buildingNames)
final buildingNamesProvider = AutoDisposeFutureProvider<List<String>>.internal(
  buildingNames,
  name: r'buildingNamesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$buildingNamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BuildingNamesRef = AutoDisposeFutureProviderRef<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
