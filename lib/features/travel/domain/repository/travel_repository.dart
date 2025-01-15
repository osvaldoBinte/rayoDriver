import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelAlertEntitie/travel_alert.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';

abstract class TravelRepository {
  Future<void> updateIdDevice();
  Future<void> acceptedTravel(int? id_travel);
  Future<void> startTravel(int? id_travel);
  Future<void> endTravel(int? id_travel);
  Future<void> cancelTravel(int? id_travel);
  Future<void> acceptWithCounteroffer(Travelwithtariff travelwithtariff);
  Future<void> offerNegotiation(Travelwithtariff travelwithtariff);
 Future<void> rejectTravelOffer(Travelwithtariff travelwithtariff);
  Future<void> driverArrival(int? id_travel);

  Future<List<TravelAlertModel>> currentTravel(bool connection);
  Future<List<TravelAlertModel>> getalltravel(bool connection);

  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<String?> fetchDeviceId();
  Future<void> confirmTravelWithTariff(Travelwithtariff travel);
}
