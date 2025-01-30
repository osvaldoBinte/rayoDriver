
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class DecodePolylineUsecase {
  final MapaRepository travelRepository;
  DecodePolylineUsecase({required this.travelRepository});
    List<LatLng> execute(String encoded)  {
    return   travelRepository.decodePolyline(encoded);
  }

}