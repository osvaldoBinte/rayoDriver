
// app_pages.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/app/splash_screen.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: RoutesNames.splashScreen,
      page: () => SplashScreen(),
    ),
    GetPage(
      name: RoutesNames.homePage,
      page: () => HomePage(
        selectedIndex: Get.arguments?['selectedIndex'] ?? 0,
      ),
    ),
    GetPage(
      name: RoutesNames.acceptTravelPage,
      page: () => AcceptTravelPage(
        idTravel: Get.arguments?['idTravel'] ?? 0,
      ),
    ),
  ];

  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada'),
      ),
    ),
  );
}