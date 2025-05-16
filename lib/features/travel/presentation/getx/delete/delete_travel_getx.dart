import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/connectivity_service.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/delete_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';

part 'delete_event.dart';
part 'delete_state.dart';

class DeleteTravelGetx extends GetxController {
  final DeleteTravelUsecase deleteTravelUsecase;
  final ConnectivityService connectivityService;

  var state = Rx<DeleteState>(DeleteInitial());

  DeleteTravelGetx(
      {required this.deleteTravelUsecase, required this.connectivityService});
  deleteTravel(DeleteTravelEvent event) async {
    state.value = DeleteLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      await deleteTravelUsecase.execute(event.id, isConnected);
      state.value = DeleteCreatedSuccessfully();
    } catch (e) {
      state.value = DeleteCreationFailure(e.toString());
    }
  }
}
