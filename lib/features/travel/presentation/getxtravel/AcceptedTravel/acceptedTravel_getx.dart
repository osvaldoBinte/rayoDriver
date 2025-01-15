import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';

part 'acceptedTravel_event.dart';
part 'acceptedTravel_state.dart';

class AcceptedtravelGetx extends GetxController {
  final AcceptedTravelUsecase acceptedTravelUsecase;

  var acceptedtravelState = Rx<AcceptedtravelState>(AcceptedtravelInitial());
  var message = ''.obs; 

  AcceptedtravelGetx({required this.acceptedTravelUsecase});
  acceptedtravel(AcceptedTravelEvent event) async {
    acceptedtravelState.value = AcceptedtravelLoading();
    try {
      await acceptedTravelUsecase.execute(event.id_travel);
      acceptedtravelState.value = AcceptedtravelSuccessfully(); // Éxito
            message.value = 'Viaje aceptado correctamente';

    } catch (e) {
      acceptedtravelState.value = AcceptedtravelError(e.toString());
            message.value = 'Ocurrió un error: viaje ya fue aceptado o falló la solicitud';

    }
  }
}
