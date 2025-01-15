part of 'travel_by_id_alert_getx.dart';

@immutable
abstract class TravelByIdAlertState {}

class TravelByIdAlertInitial extends TravelByIdAlertState {}

class TravelByIdAlertLoading extends TravelByIdAlertState {}

class TravelByIdAlertLoaded extends TravelByIdAlertState {
  final List<TravelAlertModel> travels;
  TravelByIdAlertLoaded(this.travels);
}

class TravelByIdAlertFailure extends TravelByIdAlertState {
  final String error;
  TravelByIdAlertFailure(this.error);
}
