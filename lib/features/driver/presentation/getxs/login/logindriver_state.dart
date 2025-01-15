part of 'logindriver_getx.dart';

@immutable
abstract class LogindriverState {}

class LogindriverInitial extends LogindriverState {}

class LogindriverLoading extends LogindriverState {}

class LogindriverSuccessfully extends LogindriverState {}

class LogindriverFailure extends LogindriverState {
  final String error;
  LogindriverFailure(this.error);
}
