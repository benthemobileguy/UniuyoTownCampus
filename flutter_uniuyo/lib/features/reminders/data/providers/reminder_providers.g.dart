// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reminderServiceHash() => r'49b4ebe8d1b9a4a4f3040513d1d422ec2d65412d';

/// Provider for reminder service
///
/// Copied from [reminderService].
@ProviderFor(reminderService)
final reminderServiceProvider = AutoDisposeProvider<ReminderService>.internal(
  reminderService,
  name: r'reminderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reminderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReminderServiceRef = AutoDisposeProviderRef<ReminderService>;
String _$notificationServiceHash() =>
    r'1d4f807a75b3a0104011156fa5501e4693dea597';

/// Provider for notification service
///
/// Copied from [notificationService].
@ProviderFor(notificationService)
final notificationServiceProvider =
    AutoDisposeProvider<NotificationService>.internal(
  notificationService,
  name: r'notificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationServiceRef = AutoDisposeProviderRef<NotificationService>;
String _$activeRemindersHash() => r'08c542a68f5ef1fe4e6fe8cb016616e06ee7c123';

/// Provider for all active reminders
///
/// Copied from [activeReminders].
@ProviderFor(activeReminders)
final activeRemindersProvider =
    AutoDisposeFutureProvider<List<Reminder>>.internal(
  activeReminders,
  name: r'activeRemindersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeRemindersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveRemindersRef = AutoDisposeFutureProviderRef<List<Reminder>>;
String _$buildingRemindersHash() => r'cf692bcfe1f0205e8bc2444bb878dc4ea964609e';

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

/// Provider for reminders of a specific building
///
/// Copied from [buildingReminders].
@ProviderFor(buildingReminders)
const buildingRemindersProvider = BuildingRemindersFamily();

/// Provider for reminders of a specific building
///
/// Copied from [buildingReminders].
class BuildingRemindersFamily extends Family<AsyncValue<List<Reminder>>> {
  /// Provider for reminders of a specific building
  ///
  /// Copied from [buildingReminders].
  const BuildingRemindersFamily();

  /// Provider for reminders of a specific building
  ///
  /// Copied from [buildingReminders].
  BuildingRemindersProvider call(
    String buildingId,
  ) {
    return BuildingRemindersProvider(
      buildingId,
    );
  }

  @override
  BuildingRemindersProvider getProviderOverride(
    covariant BuildingRemindersProvider provider,
  ) {
    return call(
      provider.buildingId,
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
  String? get name => r'buildingRemindersProvider';
}

/// Provider for reminders of a specific building
///
/// Copied from [buildingReminders].
class BuildingRemindersProvider
    extends AutoDisposeFutureProvider<List<Reminder>> {
  /// Provider for reminders of a specific building
  ///
  /// Copied from [buildingReminders].
  BuildingRemindersProvider(
    String buildingId,
  ) : this._internal(
          (ref) => buildingReminders(
            ref as BuildingRemindersRef,
            buildingId,
          ),
          from: buildingRemindersProvider,
          name: r'buildingRemindersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$buildingRemindersHash,
          dependencies: BuildingRemindersFamily._dependencies,
          allTransitiveDependencies:
              BuildingRemindersFamily._allTransitiveDependencies,
          buildingId: buildingId,
        );

  BuildingRemindersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.buildingId,
  }) : super.internal();

  final String buildingId;

  @override
  Override overrideWith(
    FutureOr<List<Reminder>> Function(BuildingRemindersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BuildingRemindersProvider._internal(
        (ref) => create(ref as BuildingRemindersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        buildingId: buildingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Reminder>> createElement() {
    return _BuildingRemindersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildingRemindersProvider && other.buildingId == buildingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, buildingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BuildingRemindersRef on AutoDisposeFutureProviderRef<List<Reminder>> {
  /// The parameter `buildingId` of this provider.
  String get buildingId;
}

class _BuildingRemindersProviderElement
    extends AutoDisposeFutureProviderElement<List<Reminder>>
    with BuildingRemindersRef {
  _BuildingRemindersProviderElement(super.provider);

  @override
  String get buildingId => (origin as BuildingRemindersProvider).buildingId;
}

String _$hasBuildingRemindersHash() =>
    r'cc9fdb0cd3ff681e0101baa3c6b9f28c163d9bdb';

/// Provider to check if a building has active reminders
///
/// Copied from [hasBuildingReminders].
@ProviderFor(hasBuildingReminders)
const hasBuildingRemindersProvider = HasBuildingRemindersFamily();

/// Provider to check if a building has active reminders
///
/// Copied from [hasBuildingReminders].
class HasBuildingRemindersFamily extends Family<AsyncValue<bool>> {
  /// Provider to check if a building has active reminders
  ///
  /// Copied from [hasBuildingReminders].
  const HasBuildingRemindersFamily();

  /// Provider to check if a building has active reminders
  ///
  /// Copied from [hasBuildingReminders].
  HasBuildingRemindersProvider call(
    String buildingId,
  ) {
    return HasBuildingRemindersProvider(
      buildingId,
    );
  }

  @override
  HasBuildingRemindersProvider getProviderOverride(
    covariant HasBuildingRemindersProvider provider,
  ) {
    return call(
      provider.buildingId,
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
  String? get name => r'hasBuildingRemindersProvider';
}

/// Provider to check if a building has active reminders
///
/// Copied from [hasBuildingReminders].
class HasBuildingRemindersProvider extends AutoDisposeFutureProvider<bool> {
  /// Provider to check if a building has active reminders
  ///
  /// Copied from [hasBuildingReminders].
  HasBuildingRemindersProvider(
    String buildingId,
  ) : this._internal(
          (ref) => hasBuildingReminders(
            ref as HasBuildingRemindersRef,
            buildingId,
          ),
          from: hasBuildingRemindersProvider,
          name: r'hasBuildingRemindersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasBuildingRemindersHash,
          dependencies: HasBuildingRemindersFamily._dependencies,
          allTransitiveDependencies:
              HasBuildingRemindersFamily._allTransitiveDependencies,
          buildingId: buildingId,
        );

  HasBuildingRemindersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.buildingId,
  }) : super.internal();

  final String buildingId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(HasBuildingRemindersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasBuildingRemindersProvider._internal(
        (ref) => create(ref as HasBuildingRemindersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        buildingId: buildingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasBuildingRemindersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasBuildingRemindersProvider &&
        other.buildingId == buildingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, buildingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HasBuildingRemindersRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `buildingId` of this provider.
  String get buildingId;
}

class _HasBuildingRemindersProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with HasBuildingRemindersRef {
  _HasBuildingRemindersProviderElement(super.provider);

  @override
  String get buildingId => (origin as HasBuildingRemindersProvider).buildingId;
}

String _$reminderManagerHash() => r'db8ea9a427796cb446b8b69e97658e3069d434bf';

/// State notifier for managing reminders (CRUD operations)
///
/// Copied from [ReminderManager].
@ProviderFor(ReminderManager)
final reminderManagerProvider =
    AutoDisposeAsyncNotifierProvider<ReminderManager, void>.internal(
  ReminderManager.new,
  name: r'reminderManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reminderManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReminderManager = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
