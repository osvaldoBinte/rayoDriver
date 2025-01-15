
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class EndTravelUsecase{
  final TravelRepository travelRepository;
  EndTravelUsecase({required this.travelRepository});
    Future<void>execute(int? id_travel) async{
      return await travelRepository.endTravel(id_travel);
    }

}