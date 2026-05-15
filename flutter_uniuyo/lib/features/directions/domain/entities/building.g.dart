// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BuildingImpl _$$BuildingImplFromJson(Map<String, dynamic> json) =>
    _$BuildingImpl(
      gid: (json['gid'] as num).toInt(),
      name: json['name'] as String,
      areaM2: (json['areaM2'] as num).toDouble(),
      buildingFunction: json['buildingFunction'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => (e as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );

Map<String, dynamic> _$$BuildingImplToJson(_$BuildingImpl instance) =>
    <String, dynamic>{
      'gid': instance.gid,
      'name': instance.name,
      'areaM2': instance.areaM2,
      'buildingFunction': instance.buildingFunction,
      'coordinates': instance.coordinates,
    };
