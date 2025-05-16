
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';

class ChangeAvailabilityModel extends ChangeAvailabilityEntitie {
  ChangeAvailabilityModel({required bool status})
      : super(
          status: status,
        );
  factory ChangeAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return ChangeAvailabilityModel(
      status: json['status'] ?? '',
     
    );
  }

  factory ChangeAvailabilityModel.fromEntity(ChangeAvailabilityEntitie availability) {
    return ChangeAvailabilityModel(
      status: availability.status,
   
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
     
    };
  }
}
