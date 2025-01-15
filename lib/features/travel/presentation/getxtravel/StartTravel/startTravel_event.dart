part of 'startTravel_getx.dart';

@immutable
abstract class StarttravelEvent {}

class StartravelEvent extends StarttravelEvent {
    final int? id_travel;

  StartravelEvent({required this.id_travel});
}
