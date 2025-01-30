import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/decode_polyline_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_encoded_points_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_route_usecase.dart';
class MapDataController {
  final GetRouteUsecase? getRouteUsecase;
  final GetEncodedPointsUsecase? getEncodedPointsUsecase;
  final DecodePolylineUsecase? decodePolylineUsecase;

  MapDataController({
    required this.getRouteUsecase,
    required this.getEncodedPointsUsecase,
    required this.decodePolylineUsecase,

  });

  Future<void> getRoute(LatLng start, LatLng end) async {
    await getRouteUsecase?.execute(start, end);
  }

  Future<String> getEncodedPoints() async {
    return await getEncodedPointsUsecase!.execute();
  }

  List<LatLng> decodePolyline(String encodedPoints) {
    return decodePolylineUsecase!.execute(encodedPoints);
  }
}
