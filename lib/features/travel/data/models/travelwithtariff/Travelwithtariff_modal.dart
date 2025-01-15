import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';

class TravelwithtariffModal extends Travelwithtariff {
  TravelwithtariffModal(
      {required int? id,
      required int tarifa,
      required int? driverId,
      required travelId})
      : super(id: id, tarifa: tarifa, driverId: driverId, travelId: travelId);
  factory TravelwithtariffModal.fromJson(Map<String, dynamic> json) {
    return TravelwithtariffModal(
        id: json['id'] ?? '',
        tarifa: json['tarifa'] ?? '',
        travelId: json['travelId'] ?? '',
        driverId: json['driverId'] ?? '');
  }

  factory TravelwithtariffModal.fromEntity(Travelwithtariff travelAlert) {
    return TravelwithtariffModal(
        id: travelAlert.id,
        tarifa: travelAlert.tarifa,
        driverId: travelAlert.driverId,
        travelId: travelAlert.travelId);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarifa': tarifa,
      'driverId': driverId,
      'travelId': travelId
    };
  }
}
