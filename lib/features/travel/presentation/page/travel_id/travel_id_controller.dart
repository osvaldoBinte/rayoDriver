import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel_id/map_data_controller.dart';
import 'dart:io' show Platform;
class TravelController extends GetxController {
  final TravelAlertModel travel;
  final bool isPreview;
  
  // Solo usamos MapDataController cuando no estamos en modo preview
  late final MapDataController? _mapDataController;

  final Rx<Set<Marker>> markers = Rx<Set<Marker>>({});
  final Rx<Set<Polyline>> polylines = Rx<Set<Polyline>>({});
  final Rx<LatLng?> startLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> endLocation = Rx<LatLng?>(null);
  final Rx<bool> isLoading = true.obs;
  
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  GoogleMapController? mapController;

  TravelController({
    required this.travel,
    this.isPreview = false,
  }) {
    // Solo inicializamos MapDataController si no estamos en modo preview
    if (!isPreview) {
      try {
        _mapDataController = Get.find<MapDataController>();
      } catch (e) {
        print('No se pudo encontrar MapDataController: $e');
        _mapDataController = null;
      }
    } else {
      _mapDataController = null;
    }
  }

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
      
      if (isPreview) {
        await createDirectRoute();
      } else {
        await traceRouteWithController();
      }
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
    
    // Add a small delay to ensure markers are placed before zooming
    Future.delayed(Duration(milliseconds: isPreview ? 500 : 100), () {
      if (startLocation.value != null && endLocation.value != null) {
        showBothLocations();
      }
    });
  }

  void showBothLocations() {
    if (startLocation.value == null || endLocation.value == null || mapController == null) {
      return;
    }

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

    // Add padding based on whether it's preview or full view
    double padding = isPreview ? 50.0 : 100.0;
    
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    ).catchError((error) {
      print('Error al ajustar la cámara: $error');
    });
  }


Future<void> addMarker(LatLng latLng, bool isStartPlace) async {
  MarkerId markerId = isStartPlace ? MarkerId('start') : MarkerId('destination');
  String title = isStartPlace ? 'Inicio' : 'Destino';

  // Determinar la ruta de la imagen según la plataforma
  String imagePath;
  if (isStartPlace) {
    imagePath = Platform.isAndroid 
      ? 'assets/images/mapa/origen-android.png' 
      : 'assets/images/mapa/origen-ios.png';
  } else {
    imagePath = Platform.isAndroid 
      ? 'assets/images/mapa/destino-android.png' 
      : 'assets/images/mapa/destino-ios.png';
  }

  BitmapDescriptor markerIcon;
  try {
    markerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      imagePath,
    );
  } catch (e) {
    print('Error cargando icono personalizado: $e');
    // Usar iconos predeterminados como respaldo
    markerIcon = isStartPlace 
      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) 
      : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

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
      icon: markerIcon,
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
  // Método que crea una ruta directa entre los puntos de inicio y fin (para preview)
  Future<void> createDirectRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        // Crear una ruta directa solo con los puntos de inicio y fin
        List<LatLng> routePoints = [
          startLocation.value!,
          endLocation.value!,
        ];

        polylines.value.clear();
        polylines.value.add(Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: Colors.black,
          width: 5,
        ));
        polylines.refresh();

        if (mapController != null) {
          showBothLocations();
        }
      } catch (e) {
        print('Error al crear la ruta directa: $e');
        Get.snackbar(
          'Error',
          'Error al crear la ruta directa',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
  
  // Método para simplificar polyline (usado con MapDataController)
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
  
  // Método que usa MapDataController para trazar una ruta más precisa
  Future<void> traceRouteWithController() async {
    if (startLocation.value != null && endLocation.value != null && _mapDataController != null) {
      try {
        await _mapDataController!.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await _mapDataController!.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _mapDataController!.decodePolyline(encodedPoints);

        List<LatLng> simplifiedCoordinates =
            simplifyPolyline(polylineCoordinates, 0.01);

        polylines.value.clear();
        polylines.value.add(Polyline(
          polylineId: PolylineId('route'),
          points: simplifiedCoordinates,
          color: Colors.black,
          width: 5,
        ));
        polylines.refresh();

        if (mapController != null) {
          showBothLocations();
        }
      } catch (e) {
        print('Error al trazar la ruta con controlador: $e');
        Get.snackbar(
          'Error',
          'Error al trazar la ruta',
          snackPosition: SnackPosition.BOTTOM,
        );
        // Si falla con el controlador, intentamos con ruta directa como respaldo
        await createDirectRoute();
      }
    } else {
      // Si no hay controlador disponible, usamos la ruta directa
      await createDirectRoute();
    }
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}