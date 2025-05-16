
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class StartTravelUsecase{
  final TravelRepository travelRepository;
  StartTravelUsecase({required this.travelRepository});
    Future<void>execute(int? id_travel) async{
      return await travelRepository.startTravel(id_travel);
    }

}