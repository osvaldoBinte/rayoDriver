import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelAlertEntitie/travel_alert.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class TravelRepositoryImp implements TravelRepository {
  final TravelLocalDataSource travelLocalDataSource;
  TravelRepositoryImp({required this.travelLocalDataSource});

  @override
  Future<void> updateIdDevice() async {
    return await travelLocalDataSource.updateIdDevice();
  }

  @override
  Future<List<TravelAlertModel>> currentTravel(bool connection) async {
    return await travelLocalDataSource.currentTravel(connection);
  }

  @override
  Future<List<TravelAlertModel>> getalltravel(bool connection) async {
    return await travelLocalDataSource.getalltravel(connection);
  }

  @override
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection) async {
    return await travelLocalDataSource.getbyIdtravelid(idTravel, connection);
  }

  @override
  Future<String?> fetchDeviceId() async {
    return await travelLocalDataSource.fetchDeviceId();
  }

  @override
  Future<void> acceptedTravel(int? id_travel) async {
    return await travelLocalDataSource.acceptedTravel(id_travel);
  }

  @override
  Future<void> endTravel(int? id_travel) async {
    return await travelLocalDataSource.endTravel(id_travel);
  }

  @override
  Future<void> startTravel(int? id_travel) async {
    return await travelLocalDataSource.startTravel(id_travel);
  }

  @override
  Future<void> driverArrival(int? id_travel) async {
    return await travelLocalDataSource.driverArrival(id_travel);
  }

  @override
  Future<void> confirmTravelWithTariff(Travelwithtariff travel) async {
    return await travelLocalDataSource.confirmTravelWithTariff(travel);
  }

  Future<void> cancelTravel(int? id_travel) async {
    return await travelLocalDataSource.cancelTravel(id_travel);
  }
  
  @override
  Future<void> acceptWithCounteroffer(Travelwithtariff travelwithtariff) async{
    return await travelLocalDataSource.acceptWithCounteroffer(travelwithtariff);
  }
  
  @override
  Future<void> offerNegotiation(Travelwithtariff travelwithtariff) async {
   return await travelLocalDataSource.offerNegotiation(travelwithtariff);
  }
  
  @override
  Future<void> rejectTravelOffer(Travelwithtariff travelwithtariff) async {
    return await travelLocalDataSource.rejectTravelOffer(travelwithtariff);
  }
}
