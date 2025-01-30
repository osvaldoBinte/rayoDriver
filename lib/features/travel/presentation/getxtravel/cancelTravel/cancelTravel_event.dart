part of 'cancelTravel_getx.dart';

@immutable
abstract class CanceltravelEvent {}

class CancelTravelEvent extends CanceltravelEvent {
  final Travelwithtariff travelwithtariff;
  CancelTravelEvent({required this.travelwithtariff});
}
