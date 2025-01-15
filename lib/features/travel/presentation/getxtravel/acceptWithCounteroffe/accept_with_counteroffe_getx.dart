import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accept_with_counteroffe_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';

part 'accept_with_counteroffe_event.dart';
part 'accept_with_counteroffe_state.dart';

class AcceptWithCounteroffeGetx extends GetxController {
  final AcceptWithCounteroffeUsecase acceptWithCounteroffeUsecase;

  var acceptedtravelState =
      Rx<AcceptWithCounteroffeState>(AcceptWithCounteroffeInitial());
  var message = ''.obs;

  AcceptWithCounteroffeGetx({required this.acceptWithCounteroffeUsecase});
  acceptedtravel(AcceptwithcounteroffeEvent event) async {
    acceptedtravelState.value = AcceptWithCounteroffeLoading();
    try {
      await acceptWithCounteroffeUsecase.execute(event.travel);
      acceptedtravelState.value = AcceptWithCounteroffeSuccessfully();
      message.value = 'Viaje aceptado correctamente';
    } catch (e) {
      acceptedtravelState.value = AcceptWithCounteroffeError(e.toString());
      message.value =
          'Ocurrió un error: viaje ya fue aceptado o falló la solicitud';
    }
  }
}
