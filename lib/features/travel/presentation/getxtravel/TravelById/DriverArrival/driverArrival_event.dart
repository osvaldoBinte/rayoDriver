part of 'driverArrival_getx.dart';

@immutable
abstract class DriverarrivalEvent {}

class DriverArrivalEvent extends DriverarrivalEvent {
    final int? id_travel;

  DriverArrivalEvent({required this.id_travel});
}
