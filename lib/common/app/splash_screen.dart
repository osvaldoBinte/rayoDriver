import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/id_device_get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/renew_token.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/login_driver_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {

  SplashScreen();

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? idDevice;
  bool? token;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    requestLocationPermission();
  }Future<void> requestLocationPermission() async {
  // Primero verifica si el servicio de ubicación está habilitado
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Si el servicio está deshabilitado, muestra un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Por favor activa los servicios de ubicación para usar la aplicación'),
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  // En iOS, verifica primero si ya tenemos permisos
  var status = await Permission.locationWhenInUse.status;
  
  if (status.isDenied) {
    // Si está denegado en iOS, solicita permisos mediante permission_handler
    status = await Permission.locationWhenInUse.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se requieren permisos de ubicación para usar la aplicación'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
  }
  
  // Si se necesita acceso en segundo plano, también solicítalo
  if (await Permission.locationAlways.isGranted == false) {
    var backgroundStatus = await Permission.locationAlways.request();
    if (backgroundStatus.isDenied) {
      print('Permiso de ubicación en segundo plano denegado');
      // Puedes continuar si el permiso cuando está en uso es suficiente
    }
  }

  // Después de los permisos de permission_handler, verifica con Geolocator
  LocationPermission geoPermission = await Geolocator.checkPermission();
  if (geoPermission == LocationPermission.denied) {
    geoPermission = await Geolocator.requestPermission();
    if (geoPermission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se requieren permisos de ubicación para usar la aplicación'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
  }
  
  print('Permisos de ubicación concedidos: $geoPermission');
  return;
}
void _initializeApp() async {
    token = await Get.find<RenewTokenGetx>().execute();
    idDevice = await Get.find<GetDeviceGetx>().fetchDeviceId();
    print('==== token $token idDevie $idDevice');
    if (idDevice == null || idDevice!.isEmpty) {
              print('holla des de LoginDriverPage idDevice ');

      Get.offAll(() => LoginDriverPage());
    } else if (token == true ) {
      Get.toNamed(RoutesNames.homePage, arguments: {'selectedIndex': 1});

    
          print('holla des de home ture ');
    } else {
              print('holla des de LoginDriverPage else ');

      Get.offAll(() => LoginDriverPage());
    }

   
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}