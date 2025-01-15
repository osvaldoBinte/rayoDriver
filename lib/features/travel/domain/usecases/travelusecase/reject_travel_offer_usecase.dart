import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class RejectTravelOfferUsecase {

   final TravelRepository travelRepository;
  RejectTravelOfferUsecase({required this.travelRepository});
    Future<void>execute(Travelwithtariff travelwithtariff) async{
      return await travelRepository.rejectTravelOffer(travelwithtariff);
    }
}