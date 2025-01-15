import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';

import 'package:flutter/material.dart';

class TravelController extends GetxController {
  final TravelAlertModel travel;

  final MapaLocalDataSource _travelLocalDataSource = MapaLocalDataSourceImp();
  final MapaLocalDataSource _driverTravelLocalDataSource = MapaLocalDataSourceImp();
  
  final Rx<Set<Marker>> markers = Rx<Set<Marker>>({});
  final Rx<Set<Polyline>> polylines = Rx<Set<Polyline>>({});
  final Rx<LatLng?> startLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> endLocation = Rx<LatLng?>(null);
  final Rx<bool> isLoading = true.obs;
  
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  GoogleMapController? mapController;

  TravelController({required this.travel});

  @override
  void onInit() {
    super.onInit();
    initializeMap();
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }

  Future<void> initializeMap() async {
    double? startLatitude = double.tryParse(travel.start_latitude);
    double? startLongitude = double.tryParse(travel.start_longitude);
    double? endLatitude = double.tryParse(travel.end_latitude);
    double? endLongitude = double.tryParse(travel.end_longitude);

    if (startLatitude != null &&
        startLongitude != null &&
        endLatitude != null &&
        endLongitude != null) {
      startLocation.value = LatLng(startLatitude, startLongitude);
      endLocation.value = LatLng(endLatitude, endLongitude);

      await addMarker(startLocation.value!, true);
      await addMarker(endLocation.value!, false);
      await traceRoute();
    } else {
      Get.snackbar(
        'Error',
        'Error al convertir coordenadas a números',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (startLocation.value != null && endLocation.value != null) {
      showBothLocations();
    }
  }

  // Nuevo método para mostrar ambas ubicaciones
  void showBothLocations() {
    if (startLocation.value == null || endLocation.value == null || mapController == null) {
      return;
    }

    // Crear los límites que incluyen ambos puntos
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(startLocation.value!.latitude, endLocation.value!.latitude),
        min(startLocation.value!.longitude, endLocation.value!.longitude),
      ),
      northeast: LatLng(
        max(startLocation.value!.latitude, endLocation.value!.latitude),
        max(startLocation.value!.longitude, endLocation.value!.longitude),
      ),
    );

    // Añadir padding a los límites
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        100.0, // padding en píxeles
      ),
    );
  }

  Future<void> addMarker(LatLng latLng, bool isStartPlace) async {
    MarkerId markerId = isStartPlace ? MarkerId('start') : MarkerId('destination');
    String title = isStartPlace ? 'Inicio' : 'Destino';

    Marker? existingMarker = markers.value.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => Marker(markerId: MarkerId('')),
    );

    if (existingMarker.markerId != MarkerId('')) {
      if (existingMarker.position == latLng) return;
      markers.value.remove(existingMarker);
    }

    markers.value.add(
      Marker(
        markerId: markerId,
        position: latLng,
        infoWindow: InfoWindow(title: title),
      ),
    );

    if (isStartPlace) {
      startLocation.value = latLng;
    } else {
      endLocation.value = latLng;
    }
    markers.refresh();
  }

  List<LatLng> simplifyPolyline(List<LatLng> polyline, double tolerance) {
    if (polyline.length < 3) return polyline;
    List<LatLng> simplified = [];
    simplified.add(polyline.first);
    for (int i = 1; i < polyline.length - 1; i++) {
      simplified.add(polyline[i]);
    }
    simplified.add(polyline.last);
    return simplified;
  }

  Future<void> traceRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await _travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);

        List<LatLng> simplifiedCoordinates =
            simplifyPolyline(polylineCoordinates, 0.01);

        polylines.value.clear();
        polylines.value.add(Polyline(
          polylineId: PolylineId('route'),
          points: simplifiedCoordinates,
          color: Colors.blue,
          width: 5,
        ));
        polylines.refresh();

        // Llamar a showBothLocations después de trazar la ruta
        if (mapController != null) {
          showBothLocations();
        }
      } catch (e) {
        print('Error al trazar la ruta: $e');
        Get.snackbar(
          'Error',
          'Error al trazar la ruta',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}