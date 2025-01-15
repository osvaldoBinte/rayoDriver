part of 'offer_negotiation_getx.dart';

@immutable
abstract class OfferNegotiationEvent {}

class OffernegotiationEvent extends OfferNegotiationEvent {
    final Travelwithtariff travel;

  OffernegotiationEvent({required this.travel});
}
