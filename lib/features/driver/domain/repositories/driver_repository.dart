import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

import '../../data/models/driver_model.dart';

abstract class DriverRepository {
  Future<void> loginDriver(Driver driver);
  Future<List<DriverModel>> getDriver(bool conection);
  Future<void>  removedataaccount();
  Future<void> changeavailability(ChangeAvailabilityEntitie changeAvailabilityEntitie);
  Future<bool> verifyToken();

}
