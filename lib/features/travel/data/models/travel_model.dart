import 'dart:convert';

import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';

class TravelModel extends Travel {
  TravelModel({
    String? date,
    double? start_longitude,
    double? start_latitude,
    double? end_longitude,
    double? end_latitude,
    String? kilometers,
    int? cost,
    String? client,
  }) : super(
            date: date,
            start_longitude: start_longitude,
            start_latitude: start_latitude,
            end_longitude: end_longitude,
            end_latitude: end_latitude,
            kilometers: kilometers,
            cost: cost,
            client: client);
  factory TravelModel.fromJson(Map<String, dynamic> json) {
    return TravelModel(
        date: json['data'] ?? '',
        start_longitude: json['start_longitude'] ?? '',
        start_latitude: json['start_latitude'] ?? '',
        end_longitude: json['end_longitude'] ?? '',
        end_latitude: json['end_latitude'] ?? '',
        kilometers: json['kilometers'] ?? '',
        cost: json['cost'] ?? '',
        client: json['client'] ?? '');
  }

  factory TravelModel.fromEntity(Travel travel) {
    return TravelModel(
        date: travel.date,
        start_longitude: travel.start_longitude,
        start_latitude: travel.start_latitude,
        end_longitude: travel.end_longitude,
        end_latitude: travel.end_latitude,
        kilometers: travel.kilometers,
        cost: travel.cost,
        client: travel.client);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start_longitude': start_longitude,
      'start_latitude': start_latitude,
      'end_longitude': end_longitude,
      'end_latitude': end_latitude,
      'kilometers': kilometers,
      'cost': cost,
      'client': client
    };
  }
}
