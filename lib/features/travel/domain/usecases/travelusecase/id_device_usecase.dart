
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class IdDeviceUsecase{
  final TravelRepository notificationRepository;
  IdDeviceUsecase({required this.notificationRepository});
    Future<void>execute() async{
      return await notificationRepository.updateIdDevice();
    }

}