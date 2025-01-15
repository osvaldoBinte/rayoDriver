part of 'acceptedTravel_getx.dart';

@immutable
abstract class AcceptedtravelEvent {}

class AcceptedTravelEvent extends AcceptedtravelEvent {
    final int? id_travel;

  AcceptedTravelEvent({required this.id_travel});
}
