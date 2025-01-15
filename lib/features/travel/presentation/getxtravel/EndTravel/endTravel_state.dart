part of 'endTravel_getx.dart';

@immutable
abstract class EndtravelState {}

class EndtravelInitial extends EndtravelState {}

class EndtravelLoading extends EndtravelState {}

class EndtravelLoaded extends EndtravelState {
  final int id_travel;
  EndtravelLoaded(this.id_travel);
}

class EndtravelError extends EndtravelState {
  final String message;
  EndtravelError(this.message);
}
class EndtravelSuccessfully extends EndtravelState {}
