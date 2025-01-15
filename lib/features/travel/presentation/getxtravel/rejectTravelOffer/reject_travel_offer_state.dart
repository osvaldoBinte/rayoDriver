part of 'reject_travel_offer_getx.dart';

@immutable
abstract class RejectTravelOfferState {}

class RejectTravelOfferInitial extends RejectTravelOfferState {}

class RejectTravelOfferLoading extends RejectTravelOfferState {}

class RejectTravelOfferLoaded extends RejectTravelOfferState {
  final int id_travel;
 RejectTravelOfferLoaded(this.id_travel);
}

class RejectTravelOfferError extends RejectTravelOfferState {
  final String message;
  RejectTravelOfferError(this.message);
}
class RejectTravelOfferSuccessfully extends RejectTravelOfferState {}
