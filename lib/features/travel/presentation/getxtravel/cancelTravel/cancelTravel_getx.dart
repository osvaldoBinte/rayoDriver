import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/cancel_travel_usecase.dart';

part 'cancelTravel_event.dart';
part 'cancelTravel_state.dart';

class CanceltravelGetx extends GetxController {
  final CancelTravelUsecase cancelTravelUsecase;

  var acceptedtravelState = Rx<CanceltravelState>(CanceltravelInitial());
  var message = ''.obs; 

  CanceltravelGetx({required this.cancelTravelUsecase});
  canceltravel(CancelTravelEvent event) async {
    acceptedtravelState.value = CanceltravelLoading();
    try {
      await cancelTravelUsecase.execute(event.id_travel);
      acceptedtravelState.value = CanceltravelSuccessfully();
            message.value = 'Viaje cancelado correctamente';

    } catch (e) {
      acceptedtravelState.value = CanceltravelError(e.toString());
            message.value = 'Ocurrió un error: viaje ya fue cancelado ';

    }
  }
}
