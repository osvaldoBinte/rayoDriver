
import 'package:rayo_taxi/features/driver/data/models/driver_model.dart';

import '../repositories/driver_repository.dart';

class GetDriverUsecase {
  final DriverRepository driverRepository;
  GetDriverUsecase({required this.driverRepository});
  Future<List<DriverModel>> execute(bool conection) async {
    return await driverRepository.getDriver(conection);
  }
}
