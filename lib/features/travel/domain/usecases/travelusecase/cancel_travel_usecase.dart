
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class CancelTravelUsecase{
  final TravelRepository travelRepository;
  CancelTravelUsecase({required this.travelRepository});
    Future<void>execute(Travelwithtariff travelwithtariff)  async{
      return await travelRepository.cancelTravel(travelwithtariff);
    }

}