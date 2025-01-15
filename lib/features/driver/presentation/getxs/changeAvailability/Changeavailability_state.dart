part of 'changeAvailability_getx.dart';

@immutable
abstract class ChangeavailabilityState {}

class ChangeavailabilityStateInitial extends ChangeavailabilityState {}

class ChangeavailabilityStateLoading extends ChangeavailabilityState {}

class ChangeavailabilityStateLoaded extends ChangeavailabilityState {
  final String deviceId;
 ChangeavailabilityStateLoaded(this.deviceId);
}

class ChangeavailabilityStateError extends ChangeavailabilityState {
  final String message;
  ChangeavailabilityStateError(this.message);
}
class ChangeavailabilityStateSuccessfully extends ChangeavailabilityState {}
