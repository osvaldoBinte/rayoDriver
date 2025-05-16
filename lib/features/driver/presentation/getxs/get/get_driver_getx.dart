import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/data/models/driver_model.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/get_driver_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/get_device_usecase.dart';

import '../../../../../connectivity_service.dart';
part 'get_driver_event.dart';
part 'get_driver_state.dart';

class GetDriverGetx extends GetxController {
  final GetDriverUsecase getDriverUsecase;

  var state = Rx<GetDriverState>(GetDriverInitial());
  final ConnectivityService connectivityService;

  GetDriverGetx(
      {required this.getDriverUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsEvent fetchSongDetailsEvent) async {
    state.value = GetDriverLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await getDriverUsecase.execute(isConnected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = GetDriverFailure("No hay ningun drive registrado");
        } else {
          state.value = GetDriverLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = GetDriverFailure(e.toString());
      });
    }
  }
   
}
