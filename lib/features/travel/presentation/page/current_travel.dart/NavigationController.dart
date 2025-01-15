import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NavigationState {
  final String instruction;
  final String distance;
  final String duration;
  final IconData? icon;

  NavigationState({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.icon,
  });
}

class NavigationController {
  final StreamController<NavigationState> _navigationStateController = 
      StreamController<NavigationState>.broadcast();
  Stream<NavigationState> get navigationState => _navigationStateController.stream;
  
  bool _isNavigating = false;
  Timer? _updateTimer;
  LatLng? _destination;
  GoogleMapController? _mapController;

  // Configuración de la cámara para navegación
  static const double NAVIGATION_ZOOM = 18.0;
  static const double NAVIGATION_TILT = 60.0;
  static const double NAVIGATION_BEARING_OFFSET = 0.0;

  void startNavigation(GoogleMapController mapController, LatLng destination) {
    _isNavigating = true;
    _destination = destination;
    _mapController = mapController;
    
    // Configurar la vista inicial de navegación
    _configureNavigationView();
    
    // Iniciar actualizaciones periódicas
    _startNavigationUpdates();
  }

  void stopNavigation() {
    _isNavigating = false;
    _updateTimer?.cancel();
    _destination = null;
    _mapController = null;
    _navigationStateController.add(
      NavigationState(
        instruction: "Navegación terminada",
        distance: "",
        duration: "",
      )
    );
  }

  void _configureNavigationView() async {
    if (_mapController == null) return;

    Position position = await Geolocator.getCurrentPosition();
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: NAVIGATION_ZOOM,
          tilt: NAVIGATION_TILT,
          bearing: position.heading + NAVIGATION_BEARING_OFFSET,
        ),
      ),
    );
  }

  void _startNavigationUpdates() {
    // Configurar actualizaciones de ubicación
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Actualizar cada 5 metros
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (!_isNavigating) return;
      
      _updateNavigationView(position);
      _updateNavigationState(position);
    });
  }

  void _updateNavigationView(Position position) async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: NAVIGATION_ZOOM,
          tilt: NAVIGATION_TILT,
          bearing: position.heading + NAVIGATION_BEARING_OFFSET,
        ),
      ),
    );
  }

  void _updateNavigationState(Position position) async {
    if (_destination == null) return;

    // Calcular distancia restante
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    // Aquí deberías hacer una llamada a la API de Directions para obtener
    // las instrucciones detalladas del siguiente giro
    // Por ahora, usaremos una instrucción básica
    String instruction = _getBasicInstruction(position, _destination!);
    
    _navigationStateController.add(
      NavigationState(
        instruction: instruction,
        distance: "${(distanceInMeters / 1000).toStringAsFixed(1)} km",
        duration: "${(distanceInMeters / 500).toStringAsFixed(0)} min",
        icon: _getInstructionIcon(instruction),
      )
    );
  }

  String _getBasicInstruction(Position currentPosition, LatLng destination) {
    double bearing = Geolocator.bearingBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    double relativeBearing = (bearing - currentPosition.heading + 360) % 360;

    if (relativeBearing < 45 || relativeBearing >= 315) {
      return "Continúe recto";
    } else if (relativeBearing < 135) {
      return "Gire a la derecha";
    } else if (relativeBearing < 225) {
      return "De la vuelta";
    } else {
      return "Gire a la izquierda";
    }
  }

  IconData? _getInstructionIcon(String instruction) {
    switch (instruction) {
      case "Continúe recto":
        return Icons.arrow_upward;
      case "Gire a la derecha":
        return Icons.arrow_forward;
      case "Gire a la izquierda":
        return Icons.arrow_back;
      case "De la vuelta":
        return Icons.turn_sharp_right;
      default:
        return null;
    }
  }

  void dispose() {
    _updateTimer?.cancel();
    _navigationStateController.close();
  }
}