part of 'offer_negotiation_getx.dart';

@immutable
abstract class OfferNegotiationState {}

class OfferNegotiationInitial extends OfferNegotiationState {}

class OfferNegotiationLoading extends OfferNegotiationState {}

class OfferNegotiationLoaded extends OfferNegotiationState {
  final int id_travel;
 OfferNegotiationLoaded(this.id_travel);
}

class OfferNegotiationError extends OfferNegotiationState {
  final String message;
  OfferNegotiationError(this.message);
}
class OfferNegotiationSuccessfully extends OfferNegotiationState {}
