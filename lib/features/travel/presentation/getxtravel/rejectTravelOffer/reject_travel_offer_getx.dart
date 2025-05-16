import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accept_with_counteroffe_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/offer_negotiation_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/reject_travel_offer_usecase.dart';

part 'reject_travel_offer_event.dart';
part 'reject_travel_offer_state.dart';

class RejectTravelOfferGetx extends GetxController {
  final RejectTravelOfferUsecase rejectTravelOfferUsecase;

  var acceptedtravelState =
      Rx<RejectTravelOfferState>(RejectTravelOfferInitial());
  var message = ''.obs;

  RejectTravelOfferGetx({required this.rejectTravelOfferUsecase});
  rejectTravelOfferGetx(RejecttravelOfferEvent event) async {
    acceptedtravelState.value = RejectTravelOfferLoading();
    try {
      await rejectTravelOfferUsecase.execute(event.travel);
      acceptedtravelState.value = RejectTravelOfferSuccessfully();
      message.value = 'viaje rechazado correctamente';
    } catch (e) {
      acceptedtravelState.value = RejectTravelOfferError(e.toString());
      message.value =
          'Ocurrió un error: viaje ya fue rechazado ';
    }
  }
}
