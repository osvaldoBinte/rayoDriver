part of 'delete_travel_getx.dart';

@immutable
abstract class DeleteEvent {}

class DeleteTravelEvent extends DeleteEvent {
  final String id;

  DeleteTravelEvent(this.id);
}
