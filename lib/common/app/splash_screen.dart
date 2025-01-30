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

class SplashScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;

  SplashScreen({this.initialMessage});

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
  }

Future<void> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Servicios de ubicación desactivados');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Permisos de ubicación denegados');
    }
  }
}
  void _initializeApp() async {
   // final prefs = await SharedPreferences.getInstance();
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

    if (widget.initialMessage != null) {
      print('Manejando initialMessage en SplashScreen');
      _handleNotificationClick(widget.initialMessage!);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('Datos del mensaje: ${message.data}');

    int? travelId = int.tryParse(message.data['travel'] ?? '');

    if (travelId != null) {
Get.toNamed(RoutesNames.homePage, arguments: {'selectedIndex': 2});
    } else {
      print('Error: El travelId no es un entero válido');
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
