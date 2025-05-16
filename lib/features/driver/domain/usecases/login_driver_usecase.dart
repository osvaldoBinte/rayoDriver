import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class LoginDriverUsecase{
  final DriverRepository driverRepository;
  LoginDriverUsecase({required this.driverRepository});
  Future<void>execute(Driver driver)async{
    return await driverRepository.loginDriver(driver);
  }
}