
import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/data/models/driver_model.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImp implements DriverRepository{
  final DriverLocalDataSource driverLocalDataSource;
  DriverRepositoryImp({required this.driverLocalDataSource});

  @override
  Future<void> loginDriver(Driver driver) async {
   return await driverLocalDataSource.loginDriver(driver);
  }

  @override
  Future<List<DriverModel>> getDriver(bool conection) async {
    return await driverLocalDataSource.getDriver(conection);
  }
  
  @override
  Future<void> removedataaccount() async {
   return await driverLocalDataSource.removedataaccount();
  }
  
  @override
  Future<void> changeavailability(ChangeAvailabilityEntitie changeAvailabilityEntitie) async {
   return await driverLocalDataSource.changeavailability(changeAvailabilityEntitie);

  }
  
  @override
  Future<bool> verifyToken() async {
    return await driverLocalDataSource.verifyToken();
  }
  
 

}