part of 'reject_travel_offer_getx.dart';

@immutable
abstract class RejectTravelOfferEvent {}

class RejecttravelOfferEvent extends RejectTravelOfferEvent {
    final Travelwithtariff travel;

  RejecttravelOfferEvent({required this.travel});
}
