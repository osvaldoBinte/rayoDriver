

import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class ChangeAvailabilityUsecase {
  final DriverRepository driverRepository;
  ChangeAvailabilityUsecase({required this.driverRepository});
  Future<void> execute(ChangeAvailabilityEntitie changeAvailabilityEntitie) async{
    return await driverRepository.changeavailability(changeAvailabilityEntitie);
  }
}