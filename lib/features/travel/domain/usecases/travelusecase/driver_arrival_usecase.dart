
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class DriverArrivalUsecase {

   final TravelRepository travelRepository;
  DriverArrivalUsecase({required this.travelRepository});
    Future<void>execute(int? id_travel) async{
      return await travelRepository.driverArrival(id_travel);
    }
}