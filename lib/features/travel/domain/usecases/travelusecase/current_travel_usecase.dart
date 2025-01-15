

import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class CurrentTravelUsecase {
  final TravelRepository travelRepository;
  CurrentTravelUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await travelRepository.currentTravel(connection);
  }
}