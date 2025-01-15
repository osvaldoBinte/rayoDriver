import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class MapaLocalDataSource {
  Future<void> poshTravel(Travel travel);
  Future<void> deleteTravel(String id, bool connection);
  Future<void> getRoute(LatLng startLocation, LatLng endLocation);
  List<LatLng> decodePolyline(String encoded);
  double calculateDistance(LatLng start, LatLng end);
  double degreesToRadians(double degrees);
  Future<List<dynamic>> getPlacePredictions(String input, {LatLng? location});
  Future<void> getPlaceDetailsAndMove(String placeId,
      Function(LatLng) moveToLocation, Function(LatLng) addMarker);
  Future<String> getEncodedPoints();
  Future<Map<String, dynamic>> getPlaceDetails(String placeId);
}

class MapaLocalDataSourceImp implements MapaLocalDataSource {
        String _apiKey = AppConstants.apikey;
        String _baseUrl = AppConstants.serverBase;

  String? _encodedPoints;
  

@override
Future<void> getRoute(LatLng startLocation, LatLng endLocation) async {
  final String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${endLocation.latitude},${endLocation.longitude}&key=$_apiKey&mode=driving&departure_time=now&traffic_model=best_guess';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final result = json.decode(response.body);

    // Verificar si hay rutas disponibles
    if (result['routes'] != null && result['routes'].isNotEmpty) {
      // Seleccionar la ruta con menor duración en tráfico
      var shortestRoute = result['routes'][0];
      int shortestDuration = result['routes'][0]['legs'][0]['duration_in_traffic']['value'];

      for (var route in result['routes']) {
        int duration = route['legs'][0]['duration_in_traffic']['value'];
        if (duration < shortestDuration) {
          shortestDuration = duration;
          shortestRoute = route;
        }
      }

      _encodedPoints = shortestRoute['overview_polyline']['points'];
    } else {
      throw Exception('No se encontraron rutas disponibles.');
    }
  } else {
    throw Exception('Error al obtener la ruta');
  }
}


  @override
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  @override
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;

    double dLat = degreesToRadians(end.latitude - start.latitude);
    double dLon = degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(start.latitude)) *
            cos(degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
 @override
  Future<List<dynamic>> getPlacePredictions(String input, {LatLng? location}) async {
    if (input.isEmpty) return [];

    try {
      // Codificar el input para manejar caracteres especiales y espacios
      String encodedInput = Uri.encodeComponent(input);

      // Construir la URL base
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$encodedInput'
          '&key=$_apiKey';

      // Si la ubicación está disponible, agregar parámetros de ubicación y radio
      if (location != null) {
        url += '&location=${location.latitude},${location.longitude}'
               '&radius=500'; // Radio en metros
      }

      // Realizar la solicitud HTTP GET
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final predictions = json.decode(response.body)['predictions'];
        return predictions;
      } else {
        print('Error en la respuesta de la API: ${response.body}');
        throw Exception('Error obteniendo predicciones: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Excepción al obtener predicciones: $e');
      throw Exception('Excepción al obtener predicciones: $e');
    }
  }

  @override
  Future<void> getPlaceDetailsAndMove(String placeId,
      Function(LatLng) moveToLocation, Function(LatLng) addMarker) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      final location = result['geometry']['location'];
      final LatLng latLng = LatLng(location['lat'], location['lng']);
      moveToLocation(latLng);
      addMarker(latLng);
    } else {
      throw Exception('Error obteniendo detalles del lugar');
    }
  }

  @override
  Future<String> getEncodedPoints() async {
    if (_encodedPoints != null) {
      return _encodedPoints!;
    } else {
      throw Exception('Encoded points no disponibles');
    }
  }

  @override
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      return {
        'name': result['name'],
        'lat': result['geometry']['location']['lat'],
        'lng': result['geometry']['location']['lng'],
      };
    } else {
      throw Exception('Error obteniendo detalles del lugar');
    }
  }

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<void> poshTravel(Travel travel) async {
    String? savedToken = await _getToken();

    var response = await http.post(
      Uri.parse('$_baseUrl/app_clients/travels/travels'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(TravelModel.fromEntity(travel).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      if (body['data'] != null && body['data'] is int) {
      int newTravelId = body['data'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_travel_id', newTravelId);
      print('Nuevo ID de viaje guardado en SharedPreferences: $newTravelId');
    } else {
      print('El ID del viaje no se encontró en la respuesta del servidor.');
      throw Exception('El ID del viaje no se encontró en la respuesta del servidor.');
    }
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  Future<void> _sendPendingDeletions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? storedData = prefs.getStringList('pendingDeletions');
      if (storedData != null && storedData.isNotEmpty) {
        for (String id in storedData) {
          await http.delete(
            Uri.parse('$_baseUrl/app_clients/travels/travels/Student/$id'),
          );
        }

        // Borra las operaciones pendientes después de enviarlas
        await prefs.remove('pendingDeletions');
        print('Pending deletions sent successfully');
      }
    } catch (error) {
      print('Error sending pending deletions: $error');
      // Puedes manejar el error según tus necesidades
    }
  }

  @override
  Future<void> deleteTravel(String id, bool connection) async {
    String? savedToken = await _getToken();

    if (connection) {
      try {
        final http.Response response = await http.put(
          Uri.parse('$_baseUrl/app_clients/travels/travels/cancel/$id'),
          headers: {
            'Content-Type': 'application/json',
            'x-token': savedToken ?? '',
          },
        );

        if (response.statusCode != 200) {
          print(response);
          print("error a update travel");
          throw Exception('Failed to delete user');
        } else {
          print(response);

          print("update bien travel");
        }

        await _sendPendingDeletions();
      } catch (e) {
        print('Error during network call: $e');
        throw Exception('Network error');
      }
    } else {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String>? storedData = prefs.getStringList('pendingDeletions');
        if (storedData == null) {
          storedData = [];
        }

        storedData.add(id);

        await prefs.setStringList('pendingDeletions', storedData);
        print('Delete operation saved to SharedPreferences');
      } catch (error) {
        print('Error saving delete operation to SharedPreferences: $error');
      }
    }
  }
}
