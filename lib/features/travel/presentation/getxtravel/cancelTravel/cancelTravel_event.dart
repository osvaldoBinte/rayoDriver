part of 'cancelTravel_getx.dart';

@immutable
abstract class CanceltravelEvent {}

class CancelTravelEvent extends CanceltravelEvent {
    final int? id_travel;

  CancelTravelEvent({required this.id_travel});
}
