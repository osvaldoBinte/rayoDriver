
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class CancelTravelUsecase{
  final TravelRepository travelRepository;
  CancelTravelUsecase({required this.travelRepository});
    Future<void>execute(int? id_travel) async{
      return await travelRepository.cancelTravel(id_travel);
    }

}