import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class MapaRepository {
  Future<void> poshTravel(Travel travel);
 Future<void> deleteTravel(String id, bool connection);
  Future<void> getRoute(LatLng startLocation, LatLng endLocation);
  List<LatLng> decodePolyline(String encoded);
  double calculateDistance(LatLng start, LatLng end);
  double degreesToRadians(double degrees);
  Future<List<dynamic>> getPlacePredictions(String input);
  Future<void> getPlaceDetailsAndMove(String placeId,
      Function(LatLng) moveToLocation, Function(LatLng) addMarker);
  Future<String> getEncodedPoints();
}
