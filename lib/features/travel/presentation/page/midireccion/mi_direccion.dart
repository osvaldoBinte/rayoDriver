import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MidireccionController extends GetxController {
  late GoogleMapController mapController;
  RxSet<Marker> markers = <Marker>{}.obs;
  Rxn<LatLng> driverLocation = Rxn<LatLng>();
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  StreamSubscription<Position>? positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  @override
  void onClose() {
    positionStreamSubscription?.cancel();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      Get.snackbar(
        'Error',
        'Por favor, habilita los servicios de ubicación',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Error',
          'Los permisos de ubicación están denegados',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Error',
        'Los permisos de ubicación están denegados permanentemente',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      driverLocation.value = LatLng(position.latitude, position.longitude);
      addMarker(driverLocation.value!, isDriver: true);

      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(driverLocation.value!),
        );
      }
    });
  }

 void addMarker(LatLng latLng, {bool isDriver = false}) {
  if (isDriver) {
    // Convertir markers.value a Set<Marker>
    final Set<Marker> updatedMarkers = markers.value.toSet();

    // Remover el marcador existente del conductor
    updatedMarkers.removeWhere((m) => m.markerId.value == 'driver');

    // Agregar el nuevo marcador del conductor
    updatedMarkers.add(
      Marker(
        markerId: MarkerId('driver'),
        position: latLng,
        infoWindow: InfoWindow(title: 'Conductor'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Actualizar el valor de markers
    markers.value = updatedMarkers;
  }
}

}
