

import 'package:rayo_taxi/features/driver/domain/repositories/driver_repository.dart';

class RemoveDataAccountUsecase {
  final DriverRepository driverRepository;
  RemoveDataAccountUsecase({required this.driverRepository});
  Future<void> execute() async{
    return await driverRepository.removedataaccount();
  }
}