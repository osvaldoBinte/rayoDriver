part of 'cancelTravel_getx.dart';

@immutable
abstract class CanceltravelState {}

class CanceltravelInitial extends CanceltravelState {}

class CanceltravelLoading extends CanceltravelState {}

class CanceltravelLoaded extends CanceltravelState {
  final int id_travel;
  CanceltravelLoaded(this.id_travel);
}

class CanceltravelError extends CanceltravelState {
  final String message;
  CanceltravelError(this.message);
}
class CanceltravelSuccessfully extends CanceltravelState {}
