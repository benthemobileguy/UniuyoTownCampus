// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'road.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Road _$RoadFromJson(Map<String, dynamic> json) {
  return _Road.fromJson(json);
}

/// @nodoc
mixin _$Road {
  String get name => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  String? get target => throw _privateConstructorUsedError;
  List<List<List<double>>> get coordinates =>
      throw _privateConstructorUsedError;

  /// Serializes this Road to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Road
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoadCopyWith<Road> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoadCopyWith<$Res> {
  factory $RoadCopyWith(Road value, $Res Function(Road) then) =
      _$RoadCopyWithImpl<$Res, Road>;
  @useResult
  $Res call(
      {String name,
      String? source,
      String? target,
      List<List<List<double>>> coordinates});
}

/// @nodoc
class _$RoadCopyWithImpl<$Res, $Val extends Road>
    implements $RoadCopyWith<$Res> {
  _$RoadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Road
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? source = freezed,
    Object? target = freezed,
    Object? coordinates = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      target: freezed == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String?,
      coordinates: null == coordinates
          ? _value.coordinates
          : coordinates // ignore: cast_nullable_to_non_nullable
              as List<List<List<double>>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoadImplCopyWith<$Res> implements $RoadCopyWith<$Res> {
  factory _$$RoadImplCopyWith(
          _$RoadImpl value, $Res Function(_$RoadImpl) then) =
      __$$RoadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? source,
      String? target,
      List<List<List<double>>> coordinates});
}

/// @nodoc
class __$$RoadImplCopyWithImpl<$Res>
    extends _$RoadCopyWithImpl<$Res, _$RoadImpl>
    implements _$$RoadImplCopyWith<$Res> {
  __$$RoadImplCopyWithImpl(_$RoadImpl _value, $Res Function(_$RoadImpl) _then)
      : super(_value, _then);

  /// Create a copy of Road
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? source = freezed,
    Object? target = freezed,
    Object? coordinates = null,
  }) {
    return _then(_$RoadImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      target: freezed == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String?,
      coordinates: null == coordinates
          ? _value._coordinates
          : coordinates // ignore: cast_nullable_to_non_nullable
              as List<List<List<double>>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoadImpl implements _Road {
  const _$RoadImpl(
      {required this.name,
      this.source,
      this.target,
      required final List<List<List<double>>> coordinates})
      : _coordinates = coordinates;

  factory _$RoadImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoadImplFromJson(json);

  @override
  final String name;
  @override
  final String? source;
  @override
  final String? target;
  final List<List<List<double>>> _coordinates;
  @override
  List<List<List<double>>> get coordinates {
    if (_coordinates is EqualUnmodifiableListView) return _coordinates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_coordinates);
  }

  @override
  String toString() {
    return 'Road(name: $name, source: $source, target: $target, coordinates: $coordinates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoadImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.target, target) || other.target == target) &&
            const DeepCollectionEquality()
                .equals(other._coordinates, _coordinates));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, source, target,
      const DeepCollectionEquality().hash(_coordinates));

  /// Create a copy of Road
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoadImplCopyWith<_$RoadImpl> get copyWith =>
      __$$RoadImplCopyWithImpl<_$RoadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoadImplToJson(
      this,
    );
  }
}

abstract class _Road implements Road {
  const factory _Road(
      {required final String name,
      final String? source,
      final String? target,
      required final List<List<List<double>>> coordinates}) = _$RoadImpl;

  factory _Road.fromJson(Map<String, dynamic> json) = _$RoadImpl.fromJson;

  @override
  String get name;
  @override
  String? get source;
  @override
  String? get target;
  @override
  List<List<List<double>>> get coordinates;

  /// Create a copy of Road
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoadImplCopyWith<_$RoadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
