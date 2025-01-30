
 import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class GetRouteUsecase {
  final MapaRepository travelRepository;
  GetRouteUsecase ({required this.travelRepository});
    Future<void> execute(LatLng startLocation, LatLng endLocation) async {
      return travelRepository.getRoute(startLocation, endLocation);
    }
 }