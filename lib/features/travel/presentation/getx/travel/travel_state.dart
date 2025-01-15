part of 'travel_getx.dart';

@immutable
abstract class TravelState {}

class TravelInitial extends TravelState {}

class TravelLoading extends TravelState {}

class TravelCreatedSuccessfully extends TravelState {}

class TravelCreationFailure extends TravelState {
  final String error;
  TravelCreationFailure(this.error);
}
