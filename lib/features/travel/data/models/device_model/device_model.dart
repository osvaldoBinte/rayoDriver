import '../../../domain/entities/deviceEntitie/device.dart';

class DeviceModel extends Device {
  DeviceModel({String? id_device})
      : super(
          id_device: id_device,
        );
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id_device: json['id_device'] ?? '',
     
    );
  }

  factory DeviceModel.fromEntity(Device device) {
    return DeviceModel(
      id_device: device.id_device,
   
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_device': id_device,
     
    };
  }
}
