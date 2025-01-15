import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/end_travel_usecase.dart';

part 'endTravel_event.dart';
part 'endTravel_state.dart';

class EndtravelGetx extends GetxController {
  final EndTravelUsecase endTravelUsecase;

  var endtravelState = Rx<EndtravelState>(EndtravelInitial());
  var message = ''.obs; 

  EndtravelGetx({required this.endTravelUsecase});
  endtravel(EndTravelEvent event) async {
    endtravelState.value = EndtravelLoading();
    try {
      await endTravelUsecase.execute(event.id_travel);
      endtravelState.value = EndtravelSuccessfully(); 
            message.value = 'Viaje terminado correctamente';

    } catch (e) {
      endtravelState.value =EndtravelError(e.toString());
            message.value = 'Ocurrió un error: viaje ya fue terminado o falló la solicitud';

    }
  }
}
