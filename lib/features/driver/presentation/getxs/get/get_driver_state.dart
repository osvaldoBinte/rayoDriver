part of 'get_driver_getx.dart';

@immutable
abstract class GetDriverState {}

class GetDriverInitial extends GetDriverState {}

class GetDriverLoading extends GetDriverState {}

class GetDriverLoaded extends GetDriverState {
  final List<DriverModel> drive;
  GetDriverLoaded(this.drive);
}

class GetDriverFailure extends GetDriverState {
  final String error;
  GetDriverFailure(this.error);
}
