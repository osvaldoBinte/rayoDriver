import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class ConfirmTravelWithTariffUsecase {

   final TravelRepository travelRepository;
  ConfirmTravelWithTariffUsecase({required this.travelRepository});
    Future<void>execute(Travelwithtariff travel) async{
      return await travelRepository.confirmTravelWithTariff(travel);
    }
}