// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Reminder _$ReminderFromJson(Map<String, dynamic> json) {
  return _Reminder.fromJson(json);
}

/// @nodoc
mixin _$Reminder {
  String get id =>
      throw _privateConstructorUsedError; // UUID for unique identification
  String get buildingId =>
      throw _privateConstructorUsedError; // Building.name (e.g., "B11")
  String get buildingDisplayName =>
      throw _privateConstructorUsedError; // Building.displayName (e.g., "B11 - Library")
  DateTime get scheduledDateTime => throw _privateConstructorUsedError;
  int get notificationId =>
      throw _privateConstructorUsedError; // For cancellation via flutter_local_notifications
  bool get isActive =>
      throw _privateConstructorUsedError; // false if cancelled or past
  String? get message =>
      throw _privateConstructorUsedError; // Optional reminder message
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReminderCopyWith<Reminder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReminderCopyWith<$Res> {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) then) =
      _$ReminderCopyWithImpl<$Res, Reminder>;
  @useResult
  $Res call(
      {String id,
      String buildingId,
      String buildingDisplayName,
      DateTime scheduledDateTime,
      int notificationId,
      bool isActive,
      String? message,
      DateTime? createdAt});
}

/// @nodoc
class _$ReminderCopyWithImpl<$Res, $Val extends Reminder>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? buildingId = null,
    Object? buildingDisplayName = null,
    Object? scheduledDateTime = null,
    Object? notificationId = null,
    Object? isActive = null,
    Object? message = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      buildingId: null == buildingId
          ? _value.buildingId
          : buildingId // ignore: cast_nullable_to_non_nullable
              as String,
      buildingDisplayName: null == buildingDisplayName
          ? _value.buildingDisplayName
          : buildingDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDateTime: null == scheduledDateTime
          ? _value.scheduledDateTime
          : scheduledDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReminderImplCopyWith<$Res>
    implements $ReminderCopyWith<$Res> {
  factory _$$ReminderImplCopyWith(
          _$ReminderImpl value, $Res Function(_$ReminderImpl) then) =
      __$$ReminderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String buildingId,
      String buildingDisplayName,
      DateTime scheduledDateTime,
      int notificationId,
      bool isActive,
      String? message,
      DateTime? createdAt});
}

/// @nodoc
class __$$ReminderImplCopyWithImpl<$Res>
    extends _$ReminderCopyWithImpl<$Res, _$ReminderImpl>
    implements _$$ReminderImplCopyWith<$Res> {
  __$$ReminderImplCopyWithImpl(
      _$ReminderImpl _value, $Res Function(_$ReminderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? buildingId = null,
    Object? buildingDisplayName = null,
    Object? scheduledDateTime = null,
    Object? notificationId = null,
    Object? isActive = null,
    Object? message = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ReminderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      buildingId: null == buildingId
          ? _value.buildingId
          : buildingId // ignore: cast_nullable_to_non_nullable
              as String,
      buildingDisplayName: null == buildingDisplayName
          ? _value.buildingDisplayName
          : buildingDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledDateTime: null == scheduledDateTime
          ? _value.scheduledDateTime
          : scheduledDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReminderImpl implements _Reminder {
  const _$ReminderImpl(
      {required this.id,
      required this.buildingId,
      required this.buildingDisplayName,
      required this.scheduledDateTime,
      required this.notificationId,
      required this.isActive,
      this.message,
      this.createdAt});

  factory _$ReminderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReminderImplFromJson(json);

  @override
  final String id;
// UUID for unique identification
  @override
  final String buildingId;
// Building.name (e.g., "B11")
  @override
  final String buildingDisplayName;
// Building.displayName (e.g., "B11 - Library")
  @override
  final DateTime scheduledDateTime;
  @override
  final int notificationId;
// For cancellation via flutter_local_notifications
  @override
  final bool isActive;
// false if cancelled or past
  @override
  final String? message;
// Optional reminder message
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Reminder(id: $id, buildingId: $buildingId, buildingDisplayName: $buildingDisplayName, scheduledDateTime: $scheduledDateTime, notificationId: $notificationId, isActive: $isActive, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReminderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.buildingId, buildingId) ||
                other.buildingId == buildingId) &&
            (identical(other.buildingDisplayName, buildingDisplayName) ||
                other.buildingDisplayName == buildingDisplayName) &&
            (identical(other.scheduledDateTime, scheduledDateTime) ||
                other.scheduledDateTime == scheduledDateTime) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      buildingId,
      buildingDisplayName,
      scheduledDateTime,
      notificationId,
      isActive,
      message,
      createdAt);

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReminderImplCopyWith<_$ReminderImpl> get copyWith =>
      __$$ReminderImplCopyWithImpl<_$ReminderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReminderImplToJson(
      this,
    );
  }
}

abstract class _Reminder implements Reminder {
  const factory _Reminder(
      {required final String id,
      required final String buildingId,
      required final String buildingDisplayName,
      required final DateTime scheduledDateTime,
      required final int notificationId,
      required final bool isActive,
      final String? message,
      final DateTime? createdAt}) = _$ReminderImpl;

  factory _Reminder.fromJson(Map<String, dynamic> json) =
      _$ReminderImpl.fromJson;

  @override
  String get id; // UUID for unique identification
  @override
  String get buildingId; // Building.name (e.g., "B11")
  @override
  String
      get buildingDisplayName; // Building.displayName (e.g., "B11 - Library")
  @override
  DateTime get scheduledDateTime;
  @override
  int get notificationId; // For cancellation via flutter_local_notifications
  @override
  bool get isActive; // false if cancelled or past
  @override
  String? get message; // Optional reminder message
  @override
  DateTime? get createdAt;

  /// Create a copy of Reminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReminderImplCopyWith<_$ReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
