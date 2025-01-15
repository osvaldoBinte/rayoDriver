part of 'delete_travel_getx.dart';

@immutable
abstract class DeleteState {}

class DeleteInitial extends DeleteState {}

class DeleteLoading extends DeleteState {}

class DeleteCreatedSuccessfully extends DeleteState {}

class DeleteCreationFailure extends DeleteState {
  final String error;
  DeleteCreationFailure(this.error);
}
