part of 'travel_by_id_alert_getx.dart';

@immutable
abstract class TravelByIdAlertEvent {}

class TravelByIdEventDetailsEvent {
   final int? idTravel;
  TravelByIdEventDetailsEvent({required this.idTravel});
}