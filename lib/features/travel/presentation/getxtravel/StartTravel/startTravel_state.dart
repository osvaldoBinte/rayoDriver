part of 'startTravel_getx.dart';

@immutable
abstract class StarttravelState {}

class StarttravelInitial extends StarttravelState {}

class StarttravelLoading extends StarttravelState {}

class StarttravelLoaded extends StarttravelState {
  StarttravelLoaded();
}

class StarttravelError extends StarttravelState {
  final String message;
  StarttravelError(this.message);
}
class AcceptedtravelSuccessfully extends StarttravelState {}
