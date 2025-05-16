part of 'removeDataAccount_getx.dart';

@immutable
abstract class RemovedataaccountState {}

class RemovedataaccountInitial extends RemovedataaccountState {}

class RemovedataaccountLoading extends RemovedataaccountState {}

class RemovedataaccountSuccessfully extends RemovedataaccountState {}

class RemovedataaccountFailure extends RemovedataaccountState {
  final String error;
  RemovedataaccountFailure(this.error);
}
