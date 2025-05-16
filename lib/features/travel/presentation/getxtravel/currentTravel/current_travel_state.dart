part of 'current_travel_getx.dart';

@immutable
abstract class TravelAlertState {}

class TravelAlertInitial extends TravelAlertState {}

class TravelAlertLoading extends TravelAlertState {}

class TravelAlertLoaded extends TravelAlertState {
  final List<TravelAlertModel> travels;
  TravelAlertLoaded(this.travels);
}

class TravelAlertFailure extends TravelAlertState {
  final String error;
  TravelAlertFailure(this.error);
}
