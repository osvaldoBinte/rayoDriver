import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/connectivity_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/current_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/travel_by_id_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/travels_alert_usecase.dart';

part 'travel_by_id_alert_event.dart';
part 'travel_by_id_alert_state.dart';

class TravelByIdAlertGetx extends GetxController {
  final TravelByIdUsecase travelByIdUsecase;
  var state = Rx<TravelByIdAlertState>(TravelByIdAlertInitial());
  final ConnectivityService connectivityService;

  TravelByIdAlertGetx(
      {required this.travelByIdUsecase, required this.connectivityService});                                                                                 
fetchCoDetails(TravelByIdEventDetailsEvent fetchSongDetailsEvent) async {
  state.value = TravelByIdAlertInitial();

  state.value = TravelByIdAlertLoading();
  try {
    bool isConnected = connectivityService.isConnected;
    var getDetails = await travelByIdUsecase.execute(
        fetchSongDetailsEvent.idTravel, isConnected);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (getDetails.isEmpty) {
        state.value = TravelByIdAlertFailure("No hay ningun viaje registrado");
      } else {
        state.value = TravelByIdAlertLoaded(getDetails);
      }
    });
  } catch (e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.value = TravelByIdAlertFailure(e.toString());
    });
  }
}

}
