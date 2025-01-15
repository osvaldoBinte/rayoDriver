part of 'device_getx.dart';

@immutable
abstract class DeviceState {}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceLoaded extends DeviceState {
  final String deviceId;
  DeviceLoaded(this.deviceId);
}

class DeviceError extends DeviceState {
  final String message;
  DeviceError(this.message);
}
class DeviceSuccessfully extends DeviceState {}
