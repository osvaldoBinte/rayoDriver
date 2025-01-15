import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/driver/data/models/change_availability_model.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:http/http.dart' as http;
import 'package:rayo_taxi/features/travel/data/models/device_model/device_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:convert' as convert;
import '../../../travel/presentation/getxtravel/Device/device_getx.dart';
import '../models/driver_model.dart';

abstract class DriverLocalDataSource {
  Future<void> loginDriver(Driver driver);
  Future<List<DriverModel>> getDriver(bool conection);
    Future<void> removedataaccount(); 
    Future<void> changeavailability(ChangeAvailabilityEntitie changeAvailabilityEntitie);
  Future<bool> verifyToken();

}

class DriverLocalDataSourceImp implements DriverLocalDataSource {
      String _baseUrl = AppConstants.serverBase;
  late Device device;

  @override
  Future<void> loginDriver(Driver driver) async {
      final DeviceGetx _driverGetx = Get.find<DeviceGetx>();

    var response = await http.post(
      Uri.parse('$_baseUrl/app_drivers/users/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(DriverModel.fromEntity(driver).toJson()),
    );

    dynamic body = jsonDecode(response.body);

    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      String token = body['data']['token'].toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('auth_token: ' + token);
      await _driverGetx.getDeviceId();
      print(message);
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
@override
Future<List<DriverModel>> getDriver(bool conection) async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no disponible');
  }

  if (conection) {
    try {
      var headers = {
        'x-token': token,
        'Content-Type': 'application/json',
      };

      var response = await http.get(
        Uri.parse('$_baseUrl/app_drivers/users/auth/renew'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = convert.jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          var data = jsonResponse['data'];
          DriverModel driver = DriverModel.fromJson(data);

          sharedPreferences.setString('drives', jsonEncode(driver));
          print("Datos guardados en SharedPreferences: ${jsonEncode(driver)}"); 

          return [driver];
        } else {
          throw Exception('Estructura de respuesta inesperada');
        }
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print("Error al obtener datos: $e");
      return _loadDrivesFromLocal(sharedPreferences);
    }
  } else {
    return _loadDrivesFromLocal(sharedPreferences);
  }
}

Future<List<DriverModel>> _loadDrivesFromLocal(
    SharedPreferences sharedPreferences) async {
  String drivesString = sharedPreferences.getString('drives') ?? "{}"; // Usamos "{}" para evitar errores en jsonDecode

  if (drivesString.isNotEmpty && drivesString != "{}") {
    var jsonData = jsonDecode(drivesString);
    return [DriverModel.fromJson(jsonData)];
  } else {
    throw Exception('No hay drives almacenados localmente.');
  }
}
  Future<void> removedataaccount() async{
 String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/users/drivers/remove'),
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
      print("si se ejecuto bien el removedataaccount");
    } else {
      String message = body['message'].toString();
      print('error al removedataaccount $body');
      throw Exception(message);
    }
  }
  
 
  @override
  Future<void> changeavailability(ChangeAvailabilityEntitie changeAvailabilityEntitie) async {
    String? savedToken = await _getToken();
   

    var response = await http.put(
      Uri.parse('$_baseUrl/app_drivers/users/drivers/change/availability'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(ChangeAvailabilityModel.fromEntity(changeAvailabilityEntitie).toJson()),
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
  Future<bool> verifyToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =  await AuthService().getToken();
        print('ald auth_token: $token');
    if (token == null) {
      
      throw Exception('Token no disponible');
    }
   try{
      var response = await http.get(
        Uri.parse('$_baseUrl/app_drivers/users/auth/renew'),
        headers: {
          'Content-Type': 'application/json',
          'x-token': token,
        },
      );

      dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200 ) {
            String newToken = body['token'].toString();

          await AuthService().saveToken(newToken);
        print('Nuevo auth_token: ' + newToken);
        return true;
      } else {
        print('Token no válido o fallo en la renovación');
        //await prefs.remove('auth_token');
        return false;
      }
     } catch (e) {
      print('Token no válid $e');
        return false;
      }
   
  }

}