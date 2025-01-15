import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/change_availability_usecase.dart';

part 'changeavailability_event.dart';
part 'Changeavailability_state.dart';

class ChangeavailabilityGetx extends GetxController {
  final ChangeAvailabilityUsecase changeAvailabilityUsecase;

  var deviceState = Rx<ChangeavailabilityState>(ChangeavailabilityStateInitial());

  ChangeavailabilityGetx({required this.changeAvailabilityUsecase});

  Future<void> execute(ChangeaVailabilityEvent changeaVailabilityEvent) async {
    deviceState.value = ChangeavailabilityStateLoading();
    try {
      await changeAvailabilityUsecase.execute(changeaVailabilityEvent.changeAvailabilityEntitie);
      deviceState.value = ChangeavailabilityStateSuccessfully();
    } catch (e) {
      print('error al crear id_divice ${e.toString()}');
      deviceState.value = ChangeavailabilityStateError(e.toString());
    }
  }
}
