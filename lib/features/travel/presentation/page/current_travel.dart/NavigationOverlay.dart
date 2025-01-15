import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/DriverArrival/driverArrival_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/EndTravel/endTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/StartTravel/startTravel_getx.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/cancelTravel/cancelTravel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/rejectTravelOffer/reject_travel_offer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/main.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class NavigationMode1 {
  final GoogleMapController mapController;
  Position? currentLocation;
  bool isNavigating = false;
  List<LatLng> currentRoute = [];
  String currentInstruction = '';
  double bearing = 0;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  NavigationMode1(this.mapController);

  Future<void> startNavigation({
    required LatLng destination,
    required bool isPickupMode, // true for status 3, false for status 4
  }) async {
    isNavigating = true;
    
    // Configurar el stream de ubicación con alta precisión
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Actualizar cada 5 metros
      timeLimit: null,
    );

    // Cancelar stream existente si hay uno
    await _positionStreamSubscription?.cancel();

    // Iniciar nuevo stream de ubicación
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      currentLocation = position;
      
      // Calcular bearing hacia el destino
      bearing = Geolocator.bearingBetween(
        position.latitude,
        position.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Actualizar la cámara
      await updateCamera(position);

      // Calcular distancia al destino
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Actualizar instrucciones basadas en la distancia
      updateInstructions(distanceInMeters, isPickupMode);
    });

    // Configurar la cámara inicial en modo navegación
    if (currentLocation != null) {
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLocation!.latitude, currentLocation!.longitude),
            zoom: 18,
            tilt: 60,
            bearing: bearing,
          ),
        ),
      );
    }

    // Aplicar estilo de mapa para navegación
    await mapController.setMapStyle('''
      [
        {
          "featureType": "poi",
          "elementType": "labels",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [
            {
              "weight": 2
            }
          ]
        }
      ]
    ''');
  }

  Future<void> updateCamera(Position position) async {
    if (!isNavigating) return;

    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18,
          tilt: 60,
          bearing: bearing,
        ),
      ),
    );
  }

  void updateInstructions(double distanceInMeters, bool isPickupMode) {
    if (distanceInMeters < 50) {
      currentInstruction = isPickupMode 
          ? "Has llegado al punto de recogida"
          : "Has llegado a tu destino";
    } else if (distanceInMeters < 200) {
      currentInstruction = isPickupMode
          ? "El punto de recogida está cerca"
          : "Tu destino está cerca";
    } else {
      currentInstruction = "Continúa ${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  Future<void> stopNavigation() async {
    isNavigating = false;
    await _positionStreamSubscription?.cancel();
    await mapController.setMapStyle(null); // Restaurar estilo original
    currentInstruction = '';
  }

  Widget buildNavigationUI() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      top: isNavigating ? 0 : -200,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.navigation, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentInstruction,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isNavigating) ...[
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.5, // Progreso del segmento actual
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildNavigationButton({
    required VoidCallback onPressed,
    required bool isPickupMode,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(isNavigating 
        ? 'Salir de navegación' 
        : isPickupMode 
          ? 'Navegar al pasajero' 
          : 'Navegar al destino'
      ),
      icon: Icon(isNavigating ? Icons.close : Icons.navigation),
      backgroundColor: Colors.blue,
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
  }
}