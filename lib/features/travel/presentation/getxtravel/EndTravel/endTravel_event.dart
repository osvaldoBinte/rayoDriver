part of 'endTravel_getx.dart';

@immutable
abstract class EndtravelEvent {}

class EndTravelEvent extends EndtravelEvent {
    final int? id_travel;

  EndTravelEvent({required this.id_travel});
}
