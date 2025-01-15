part of 'acceptedTravel_getx.dart';

@immutable
abstract class AcceptedtravelState {}

class AcceptedtravelInitial extends AcceptedtravelState {}

class AcceptedtravelLoading extends AcceptedtravelState {}

class AcceptedtravelLoaded extends AcceptedtravelState {
  final int id_travel;
  AcceptedtravelLoaded(this.id_travel);
}

class AcceptedtravelError extends AcceptedtravelState {
  final String message;
  AcceptedtravelError(this.message);
}
class AcceptedtravelSuccessfully extends AcceptedtravelState {}
