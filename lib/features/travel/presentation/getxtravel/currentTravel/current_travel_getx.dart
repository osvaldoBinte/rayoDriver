import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/connectivity_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/current_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/travels_alert_usecase.dart';

part 'current_travel_event.dart';
part 'current_travel_state.dart';

class CurrentTravelGetx extends GetxController {
  final CurrentTravelUsecase currentTravelUsecase;
  var state = Rx<TravelAlertState>(TravelAlertInitial());
  final ConnectivityService connectivityService;

  CurrentTravelGetx(
      {required this.currentTravelUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsEvent fetchSongDetailsEvent) async {
    state.value = TravelAlertLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await currentTravelUsecase.execute(isConnected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = TravelAlertFailure("No hay ningun viaje  registrado");
        } else {
          state.value = TravelAlertLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = TravelAlertFailure(e.toString());
      });
    }
  }
}
