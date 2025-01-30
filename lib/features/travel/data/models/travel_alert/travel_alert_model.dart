import 'package:rayo_taxi/features/travel/domain/entities/travelAlertEntitie/travel_alert.dart';

class TravelAlertModel extends TravelAlert {
  TravelAlertModel(
      {required int id,
      required String date,
      required String start_longitude,
      required String start_latitude,
      required String end_longitude,
      required String end_latitude,
      required num kilometers,
      required int id_client,
      required int id_company,
      required int id_status,
      required String status,
      required double cost,
      String? client,
      final String? tarifa,
      required String waiting_for,
      required String id_travel_driver,
      required String path_photo,
      required String plates,
      required int qualification,
      })
      : super(
            id: id,
            date: date,
            start_longitude: start_longitude,
            start_latitude: start_latitude,
            end_longitude: end_longitude,
            end_latitude: end_latitude,
            kilometers: kilometers,
            id_client: id_client,
            id_company: id_company,
            id_status: id_status,
            status: status,
            cost: cost,
            client: client,
            tarifa: tarifa,
            waiting_for: waiting_for,
            id_travel_driver: id_travel_driver,
            path_photo: path_photo,
            plates: plates,
            qualification: qualification,
           );
  factory TravelAlertModel.fromJson(Map<String, dynamic> json) {
    return TravelAlertModel(
        id: json['id'],
        date: json['date'],
        start_longitude: json['start_longitude'],
        start_latitude: json['start_latitude'],
        end_longitude: json['end_longitude'],
        end_latitude: json['end_latitude'],
        kilometers: json['kilometers'],
        id_client: json['id_client'],
        id_company: json['id_company'],
        id_status: json['id_status'],
        status: json['status'] ?? '',
        cost: (json['cost'] as num).toDouble(),
        client: json['client'],
        tarifa: json['tarifa']?.toString(),
        waiting_for: json['waiting_for'],
        id_travel_driver: json['id_travel_driver'] ?? '0',
        path_photo: json['path_photo'] ?? '',
        plates: json['plates'] ?? '',
        qualification: json['qualification'] ?? 0,
       // model: json['model']??''
        );
  }

  factory TravelAlertModel.fromEntity(TravelAlert travelAlert) {
    return TravelAlertModel(
      id: travelAlert.id,
      date: travelAlert.date,
      start_longitude: travelAlert.start_longitude,
      start_latitude: travelAlert.start_latitude,
      end_longitude: travelAlert.end_longitude,
      end_latitude: travelAlert.end_latitude,
      kilometers: travelAlert.kilometers,
      id_client: travelAlert.id_client,
      id_company: travelAlert.id_company,
      id_status: travelAlert.id_status,
      status: travelAlert.status,
      cost: travelAlert.cost,
      client: travelAlert.client,
      tarifa: travelAlert.tarifa,
      waiting_for: travelAlert.waiting_for,
      id_travel_driver: travelAlert.id_travel_driver,
      path_photo: travelAlert.path_photo,
      plates: travelAlert.plates,
      qualification: travelAlert.qualification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'start_longitude': start_longitude,
      'start_latitude': start_latitude,
      'end_longitude': end_longitude,
      'end_latitude': end_latitude,
      'kilometers': kilometers,
      'id_client': id_client,
      'id_company': id_company,
      'id_status': id_status,
      'status': status,
      'cost': cost,
      'client': client,
      'tarifa': tarifa,
      'waiting_for': waiting_for,
      'id_travel_driver': id_travel_driver,
      'path_photo': path_photo,
      'plates': plates,
      'qualification':qualification,
    };
  }
}
