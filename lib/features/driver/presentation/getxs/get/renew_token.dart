import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/renew_token_usecase.dart';

class RenewTokenGetx extends GetxController {
  final RenewTokenUsecase renewTokenUsecase;

  RenewTokenGetx({required this.renewTokenUsecase});

  Future<bool> execute() async {
    try {
      final isValid = await renewTokenUsecase.execute();
      return isValid;
    } catch (e) {
      print("Error al renovar el token: $e ");
     
      return false;
    }
  }
}
