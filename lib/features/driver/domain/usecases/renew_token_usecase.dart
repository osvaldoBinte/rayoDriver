
import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class RenewTokenUsecase {
  final DriverRepository driverRepository;
  RenewTokenUsecase({required this.driverRepository});
 Future<bool> execute() async{
    return await driverRepository.verifyToken();
  }
}