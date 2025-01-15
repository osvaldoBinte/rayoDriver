import 'package:rayo_taxi/features/travel/domain/repository/travel_repository.dart';

class GetDeviceUsecase{
  final TravelRepository notificationRepository;
  GetDeviceUsecase({required this.notificationRepository});
    Future<String?> execute() async{
      return await notificationRepository.fetchDeviceId();
    }

}