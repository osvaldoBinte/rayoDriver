part of 'travel_getx.dart';

@immutable
abstract class TravelEvent {}

class CreateTravelEvent extends TravelEvent {
  final Travel travel;

  CreateTravelEvent(this.travel);
}
