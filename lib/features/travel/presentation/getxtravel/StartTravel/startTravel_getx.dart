import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/start_travel_usecase.dart';

part 'startTravel_event.dart';
part 'startTravel_state.dart';

class StarttravelGetx extends GetxController {
  final StartTravelUsecase startTravelUsecase;

  var starttravelState = Rx<StarttravelState>(StarttravelInitial());
  var message = ''.obs; 

  StarttravelGetx({required this.startTravelUsecase});
  starttravel(StartravelEvent event) async {
    starttravelState.value = StarttravelLoading();
    try {
      await startTravelUsecase.execute(event.id_travel);
      starttravelState.value = AcceptedtravelSuccessfully(); // Éxito
            message.value = 'Viaje iniciado correctamente';

    } catch (e) {
      starttravelState.value = StarttravelError(e.toString());
            message.value = 'Ocurrió un error: viaje ya fue iniciado o falló la solicitud';

    }
  }
}
