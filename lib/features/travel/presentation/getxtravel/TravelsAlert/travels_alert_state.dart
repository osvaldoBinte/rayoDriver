part of 'travels_alert_getx.dart';

@immutable
abstract class TravelsAlertState {}

class TravelsAlertInitial extends TravelsAlertState {}

class TravelsAlertLoading extends TravelsAlertState {}

class TravelsAlertLoaded extends TravelsAlertState {
  final List<TravelAlertModel> travels;
  TravelsAlertLoaded(this.travels);
}

class TravelsAlertFailure extends TravelsAlertState {
  final String error;
  TravelsAlertFailure(this.error);
}
