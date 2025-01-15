import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/posh_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelAlertEntitie/travel_alert.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/confirm_travel_with_tariff_usecase.dart';

part 'travelWithTariff_event.dart';
part 'travelWithTariff_state.dart';
class TravelwithtariffGetx   extends GetxController {
  final ConfirmTravelWithTariffUsecase confirmTravelWithTariffUsecase;
  var state = Rx<TravelwithtariffState>(TravelwithtariffInitial());
  
  TravelwithtariffGetx({required this.confirmTravelWithTariffUsecase});

  travelwithtariffGetx(TravelWithtariffEvent event) async {
    print("TravelGetx.Travelwithtariff: Start");
    state.value = TravelwithtariffLoading();
    try {
      await confirmTravelWithTariffUsecase.execute(event.travel);
      print("TravelGetx.Travelwithtariff: After execute");
      print("object");
      state.value = TravelwithtariffSuccessfully();
    } catch (e) {
      print("TravelGetx.Travelwithtariff: Exception - $e");
      state.value = TravelwithtariffFailure(e.toString());
    }
    print("TravelGetx.Travelwithtariff: End");
  }
}
