import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class MapaRepositoryImp implements MapaRepository{
  final MapaLocalDataSource mapaLocalDataSource;
  MapaRepositoryImp({required this.mapaLocalDataSource});

  @override
  double calculateDistance(LatLng start, LatLng end) {
   return  mapaLocalDataSource.calculateDistance(start, end);
  }

  @override
  List<LatLng> decodePolyline(String encoded) {
   return  mapaLocalDataSource.decodePolyline(encoded);
  }

  @override
  double degreesToRadians(double degrees) {
    return  mapaLocalDataSource.degreesToRadians(degrees);
  }

  @override
  Future<String> getEncodedPoints() async {
    return await mapaLocalDataSource.getEncodedPoints();
  }

  @override
  Future<void> getPlaceDetailsAndMove(String placeId, Function(LatLng p1) moveToLocation, Function(LatLng p1) addMarker) async {
    return await mapaLocalDataSource.getPlaceDetailsAndMove(placeId, moveToLocation, addMarker);
  }

  @override
  Future<List> getPlacePredictions(String input) async {
    return await mapaLocalDataSource.getPlacePredictions(input);
  }

  @override
  Future<void> getRoute(LatLng startLocation, LatLng endLocation) async {
    return await mapaLocalDataSource.getRoute(startLocation, endLocation);
  }

  @override
  Future<void> poshTravel(Travel travel) async {
    return await mapaLocalDataSource.poshTravel(travel);
  }
  
  @override
 Future<void> deleteTravel(String id, bool connection) async {
    return await mapaLocalDataSource.deleteTravel(id,connection);
  }

}