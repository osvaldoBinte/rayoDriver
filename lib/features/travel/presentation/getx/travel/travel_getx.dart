import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';

part 'travel_event.dart';
part 'travel_state.dart';
class TravelGetx extends GetxController {
  final PoshTravelUsecase poshTravelUsecase;
  var state = Rx<TravelState>(TravelInitial());
  TravelGetx({required this.poshTravelUsecase});

  poshTravel(CreateTravelEvent event) async {
    print("TravelGetx.poshTravel: Start");
    state.value = TravelLoading();
    try {
      await poshTravelUsecase.execute(event.travel);
      print("TravelGetx.poshTravel: After execute");
      print("object");
      state.value = TravelCreatedSuccessfully();
    } catch (e) {
      print("TravelGetx.poshTravel: Exception - $e");
      state.value = TravelCreationFailure(e.toString());
    }
    print("TravelGetx.poshTravel: End");
  }
}
