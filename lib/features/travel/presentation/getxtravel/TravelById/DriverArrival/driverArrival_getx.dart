import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/driver_arrival_usecase.dart';

part 'driverArrival_event.dart';
part 'driverArrival_state.dart';

class DriverarrivalGetx extends GetxController {
  final DriverArrivalUsecase driverArrivalUsecase;

  var driverarrivalState = Rx<DriverarrivalState>(DriverarrivalInitial());
  var message = ''.obs; 

  DriverarrivalGetx({required this.driverArrivalUsecase});
  driverarrival(DriverArrivalEvent event) async {
    driverarrivalState.value = DriverarrivalLoading();
    try {
      await driverArrivalUsecase.execute(event.id_travel);
      driverarrivalState.value = DriverarrivalSuccessfully(); 
            message.value = 'Viaje aceptado correctamente';

    } catch (e) {
      driverarrivalState.value = DriverarrivalError(e.toString());
            message.value = 'Ocurrió un error: notificasion no se envio ';

    }
  }
}
