import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accept_with_counteroffe_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/offer_negotiation_usecase.dart';

part 'offer_negotiation_event.dart';
part 'offer_negotiation_state.dart';

class OfferNegotiationGetx extends GetxController {
  final OfferNegotiationUsecase offerNegotiationUsecase;

  var acceptedtravelState =
      Rx<OfferNegotiationState>(OfferNegotiationInitial());
  var message = ''.obs;

  OfferNegotiationGetx({required this.offerNegotiationUsecase});
  OfferNegotiationtravel(OffernegotiationEvent event) async {
    acceptedtravelState.value = OfferNegotiationLoading();
    try {
      await offerNegotiationUsecase.execute(event.travel);
      acceptedtravelState.value = OfferNegotiationSuccessfully();
      message.value = 'Negociación enviada correctamente';
    } catch (e) {
      acceptedtravelState.value = OfferNegotiationError(e.toString());
      print('============= currió un error $e');
      message.value =
          'Error: La negociación ya fue enviada ';
    }
  }
}
