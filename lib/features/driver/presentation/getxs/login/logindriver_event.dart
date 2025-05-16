part of 'logindriver_getx.dart';

@immutable
abstract class LogindriverEvent {}

class LoginDriverEvent extends LogindriverEvent {
  final Driver driver;

  LoginDriverEvent(this.driver);
}
