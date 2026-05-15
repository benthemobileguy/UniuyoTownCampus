// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'road.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoadImpl _$$RoadImplFromJson(Map<String, dynamic> json) => _$RoadImpl(
      name: json['name'] as String,
      source: json['source'] as String?,
      target: json['target'] as String?,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => (e as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );

Map<String, dynamic> _$$RoadImplToJson(_$RoadImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'source': instance.source,
      'target': instance.target,
      'coordinates': instance.coordinates,
    };
