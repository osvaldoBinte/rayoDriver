part of 'driverArrival_getx.dart';

@immutable
abstract class DriverarrivalState {}

class DriverarrivalInitial extends DriverarrivalState {}

class DriverarrivalLoading extends DriverarrivalState {}

class DriverarrivalLoaded extends DriverarrivalState {
  final int id_travel;
  DriverarrivalLoaded(this.id_travel);
}

class DriverarrivalError extends DriverarrivalState {
  final String message;
  DriverarrivalError(this.message);
}
class DriverarrivalSuccessfully extends DriverarrivalState {}
