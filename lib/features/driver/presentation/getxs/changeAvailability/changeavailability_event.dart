part of 'changeAvailability_getx.dart';

@immutable
abstract class ChangeavailabilityEvent {}

class ChangeaVailabilityEvent extends ChangeavailabilityEvent {
  final ChangeAvailabilityEntitie changeAvailabilityEntitie;
  ChangeaVailabilityEvent({required  this.changeAvailabilityEntitie});
}
