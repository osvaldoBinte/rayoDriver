import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/travel/data/models/travelwithtariff/Travelwithtariff_modal.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelAlertEntitie/travel_alert.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../models/device_model/device_model.dart';
import '../models/travel_alert/travel_alert_model.dart';

abstract class TravelLocalDataSource {
  Future<void> updateIdDevice();

  Future<void> acceptedTravel(int? id_travel);
  Future<void> driverArrival(int? id_travel);
  Future<void> cancelTravel(int? id_travel);
  Future<void> acceptWithCounteroffer(Travelwithtariff travelwithtariff);
  Future<void> offerNegotiation(Travelwithtariff travelwithtariff);


  Future<void> rejectTravelOffer(Travelwithtariff travelwithtariff);

  Future<void> startTravel(int? id_travel);
  Future<void> endTravel(int? id_travel);

  Future<List<TravelAlertModel>> currentTravel(bool connection);

  Future<List<TravelAlertModel>> getalltravel(bool connection);

  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<String?> fetchDeviceId();

  Future<void> confirmTravelWithTariff(Travelwithtariff travel);
}

class TravelLocalDataSourceImp implements TravelLocalDataSource {
  

  
  String _baseUrl = AppConstants.serverBase;

  late Device device;

  @override
  Future<void> updateIdDevice() async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/users/drivers/device'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(DeviceModel.fromEntity(device).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el id device");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<List<TravelAlertModel>> currentTravel(bool connection) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    if (connection) {
      try {
        var headers = {
          'x-token': token,
          'Content-Type': 'application/json',
        };

        print('Realizando la solicitud a $_baseUrl/auth/renew...');
        var response = await http.get(
          Uri.parse('$_baseUrl/app_drivers/users/auth/renew'),
          headers: headers,
        );

        print('Código de estado de la respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          final jsonResponse = convert.jsonDecode(response.body);
          print('Respuesta JSON: $jsonResponse');

          if (jsonResponse['data'] != null &&
              jsonResponse['data']['current_travel'] != null) {
            var travel = jsonResponse['data']['current_travel'];

            print('hola soy current_travel: $travel');

            // Cambiar aquí
            TravelAlertModel travelAlert = TravelAlertModel.fromJson(travel);

            print('Viaje mapeado: $travelAlert');
            sharedPreferences.setString(
                'current_travel', jsonEncode(travelAlert.toJson()));

            // print('Viaje guardado en SharedPreferences');
            //sharedPreferences.setInt('current_travel_id', travelAlert.id);

            print(
                'ID del viaje guardado en SharedPreferences: ${travelAlert.id}');
            print("ultimo viaje 200");
            return [travelAlert];
          } else {
            throw Exception('Estructura de respuesta inesperada  ultimo viaje');
          }
        } else {
          throw Exception(
              'Error en la petición de ultimo viaje: ${response.statusCode}');
        }
      } catch (e) {
        print('Error capturado: $e');
        return _loadtravelFromLocal(sharedPreferences);
      }
    } else {
      print('Conexión no disponible, cargando desde SharedPreferences...');
      return _loadtravelFromLocal(sharedPreferences);
    }
  }

  Future<List<TravelAlertModel>> _loadtravelsFromLocal(
      SharedPreferences sharedPreferences) async {
    String clientsString = sharedPreferences.getString('travelsAlert') ?? "[]";
    print('Cargando viajes de SharedPreferences: $clientsString');

    List<dynamic> body = jsonDecode(clientsString);

    if (body.isNotEmpty) {
      return body
          .map<TravelAlertModel>(
              (travels) => TravelAlertModel.fromJson(travels))
          .toList();
    } else {
      print(body);
      throw Exception('No hay viajes. sharedPreferences');
    }
  }

  Future<List<TravelAlertModel>> _loadtravelFromLocal(
      SharedPreferences sharedPreferences) async {
    String clientsString =
        sharedPreferences.getString('current_travel') ?? "[]";
    print('Cargando viajes de SharedPreferences: $clientsString');

    List<dynamic> body = jsonDecode(clientsString);

    if (body.isNotEmpty) {
      return body
          .map<TravelAlertModel>(
              (travels) => TravelAlertModel.fromJson(travels))
          .toList();
    } else {
      print(body);
      throw Exception('No hay viajes. sharedPreferences');
    }
  }

  @override
  Future<List<TravelAlertModel>> getalltravel(bool connection) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    if (connection) {
      try {
        var headers = {
          'x-token': token,
          'Content-Type': 'application/json',
        };

        var response = await http.get(
          Uri.parse('$_baseUrl/app_drivers/users/auth/renew'),
          headers: headers,
        );

        print('Código de estado de la respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          final jsonResponse = convert.jsonDecode(response.body);
          print('Respuesta JSON: $jsonResponse');

          if (jsonResponse['data'] != null &&
              jsonResponse['data']['travels'] != null) {
            var travels = jsonResponse['data']['travels'];

            print('Datos de viajes recibidos: $travels');

            List<TravelAlertModel> travelsAlert = (travels as List)
                .map((travel) => TravelAlertModel.fromJson(travel))
                .toList();

            print('Viajes mapeados:getalltravel $travelsAlert');
            sharedPreferences.setString(
                'travelsAlert ', jsonEncode(travelsAlert));
            print(
                'Viajes guardados en SharedPreferences:getalltravel ${travelsAlert.length}');

            return travelsAlert;
          } else {
            throw Exception('Estructura de respuesta inesperada');
          }
        } else {
          throw Exception('Error en la petición: ${response.statusCode}');
        }
      } catch (e) {
        print('Error capturado: $e');
        return _loadtravelsFromLocal(sharedPreferences);
      }
    } else {
      print('Conexión no disponible, cargando desde SharedPreferences...');
      return _loadtravelsFromLocal(sharedPreferences);
    }
  }
@override
Future<List<TravelAlertModel>> getbyIdtravelid(
    int? idTravel, bool connection) async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  print('id desde idTravel $idTravel');
  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no disponible');
  }

  try {
    // Siempre intentar primero obtener los datos desde la red
    if (connection) {
      var headers = {
        'x-token': token,
        'Content-Type': 'application/json',
      };

      var response = await http.get(
        Uri.parse('$_baseUrl/app_drivers/travels/travels/$idTravel'), 
        headers: headers,
      );

      print('Código de estado de la respuesta: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = convert.jsonDecode(response.body);
        print('Respuesta JSON: $jsonResponse');

        if (jsonResponse['data'] != null) {
          var travelData = jsonResponse['data'];

          print('Datos de viaje recibido: $travelData');

          TravelAlertModel travelAlertbyid =
              TravelAlertModel.fromJson(travelData);

          print('Viaje mapeado: $travelAlertbyid');
          
          await sharedPreferences.remove('getalltravelid');
          await sharedPreferences.setString(
            'getalltravelid',
            jsonEncode(travelAlertbyid.toJson()),
          );

          return [travelAlertbyid];
        } else {
          return await _loadtravelbyIDFromLocal(sharedPreferences);
        }
      }
    }

    return await _loadtravelbyIDFromLocal(sharedPreferences);

  } catch (e) {
    print('Error capturado: $e');
    
         throw Exception('No se pudo cargar el viaje. Verifique su conexión.$e idTravel $idTravel');

  }
}

Future<List<TravelAlertModel>> _loadtravelbyIDFromLocal(
    SharedPreferences sharedPreferences) async {
  String travelString = sharedPreferences.getString('getalltravelid') ?? "";

  if (travelString.isNotEmpty) {
    try {
      print('Cargando viaje de SharedPreferences: $travelString');

      Map<String, dynamic> travelMap = convert.jsonDecode(travelString);
      TravelAlertModel travelAlert = TravelAlertModel.fromJson(travelMap);

      return [travelAlert]; 
    } catch (e) {
      print('Error al parsear datos locales: $e');
      throw Exception('Error al procesar datos de viaje almacenados');
    }
  } else {
    print('No hay viajes en SharedPreferences');
    throw Exception('No hay viajes en SharedPreferences');
  }
}

  @override
  Future<String?> fetchDeviceId() async {
    try {
      final String url = '$_baseUrl/app_drivers/users/auth/renew';
      print('Realizando la solicitud a $url...');

      String? token = await _getToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Decodificar la respuesta en JSON
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extraer el `id_device` del JSON
        String? idDevice = jsonResponse['data']['id_device'];
        print('ID del dispositivo obtenido: $idDevice');

        return idDevice; // Retornar el id_device
      } else {
        // Manejo de errores cuando el estado no es 200
        print('Error en la solicitud: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Manejo de excepciones
      print('Error obteniendo el id_device: $e');
      return null;
    }
  }

  @override
  Future<void> acceptedTravel(int? id_travel) async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/accepted/$id_travel'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(DeviceModel.fromEntity(device).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el id device");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  @override
  Future<void> endTravel(int? id_travel) async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/end/$id_travel'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(DeviceModel.fromEntity(device).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el id device");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  @override
  Future<void> startTravel(int? id_travel) async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/start/$id_travel'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(DeviceModel.fromEntity(device).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el id device");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  @override
  Future<void> driverArrival(int? id_travel) async {
    String? savedToken = await _getToken();

    //device = Device(id_device: token);

    var response = await http.post(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/notify/$id_travel'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el mandar notificattion de driver cerca");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  @override
  Future<void> confirmTravelWithTariff(Travelwithtariff travel) async {
    String? savedToken = await _getToken();

    var response = await http.post(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/confirmTravelWithTariff'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(TravelwithtariffModal.fromEntity(travel).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print('mi mensaje de confirmTravelWithTariff $message');
         //   print(message);

    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }
  
  @override
  Future<void> cancelTravel(int? id_travel) async {
    String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/cancelTravel/$id_travel'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el cancelTravel");
    } else {
      String message = body['message'].toString();
      print('error al cancelTravel $body');
      throw Exception(message);
    }
  }
  
  @override
  Future<void> acceptWithCounteroffer(Travelwithtariff travelwithtariff) async {
    String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse(
          '$_baseUrl/app_drivers/travels/travels/acceptWithCounteroffer/'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
            body: jsonEncode(TravelwithtariffModal.fromEntity(travelwithtariff).toJson()),

    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el confirmTravelWithTariff");
    } else {
      String message = body['message'].toString();
      print('error al confirmTravelWithTariff $body');
      throw Exception(message);
    }
  }
  
  @override
  Future<void> offerNegotiation(Travelwithtariff travelwithtariff) async {
   String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/offerNegotiation'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(TravelwithtariffModal.fromEntity(travelwithtariff).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print('mi mensaje de confirmTravelWithTariff $message');
         //   print(message);

    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }
  
  @override
  Future<void> rejectTravelOffer(Travelwithtariff travelwithtariff) async {
    String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/travels/travels/rejectTravelOffer'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(TravelwithtariffModal.fromEntity(travelwithtariff).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print('mi mensaje de confirmTravelWithTariff $message');
         //   print(message);

    } else {
      String message = body['message'].toString();
      print('ete es mi error en rejectTravelOffer s$body');
      throw Exception(message);
    }
  }
  

}
