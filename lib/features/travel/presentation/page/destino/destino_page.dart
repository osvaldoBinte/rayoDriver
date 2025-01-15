import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
class TravelRoute2 extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  TravelRoute2({required this.travelList});

  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<TravelRoute2> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng? _driverLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  MapaLocalDataSource _travelLocalDataSource = MapaLocalDataSourceImp();
  MapaLocalDataSource _driverTravelLocalDataSource =
      MapaLocalDataSourceImp();
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? _lastDriverPositionForRouteUpdate;
  final double _routeUpdateDistanceThreshold = 5;

  @override
  void initState() {
    super.initState();

    if (widget.travelList.isNotEmpty) {
      var travelAlert = widget.travelList[0];

      double? endLatitude = double.tryParse(travelAlert.end_latitude);
      double? endLongitude = double.tryParse(travelAlert.end_longitude);

      if (endLatitude != null && endLongitude != null) {
        _endLocation = LatLng(endLatitude, endLongitude);
        _addMarker(_endLocation!, false);

        _getCurrentLocation().then((_) {
          if (_startLocation != null) {
            _addMarker(_startLocation!, true); // Marcador para la ubicación inicial
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al convertir coordenadas de destino a números')),
          );
        });
      }
    }

    // Monitorear cambios en la ubicación del conductor
    _listenToDriverLocationChanges();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    LatLngBounds bounds = _createLatLngBoundsFromMarkers();
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _createLatLngBoundsFromMarkers() {
    if (_markers.isEmpty) {
      return LatLngBounds(
        northeast: _center,
        southwest: _center,
      );
    }

    List<LatLng> positions = _markers.map((m) => m.position).toList();
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void _addMarker(LatLng latLng, bool isStartPlace, {bool isDriver = false}) {
    if (!mounted) return;
    setState(() {
      if (isDriver) {
        // Actualiza el marcador existente del conductor en lugar de agregar uno nuevo
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(
          Marker(
            markerId: MarkerId('driver'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Conductor'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _driverLocation = latLng;
      }  else {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Destino'),
          ),
        );
        _endLocation = latLng;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, habilita los servicios de ubicación')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Los permisos de ubicación están denegados')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Los permisos de ubicación están denegados permanentemente')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    if (!mounted) return;

    setState(() {
      _startLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _listenToDriverLocationChanges() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Actualiza cada 5 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        // Actualiza la ubicación del conductor sin agregar otro marcador
        _driverLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_driverLocation!, false, isDriver: true); // Actualiza el marcador del conductor
      });

      _updateDriverRouteIfNeeded();
    });
  }

  void _updateDriverRouteIfNeeded() {
    if (_driverLocation == null || _startLocation == null) return;

    if (_lastDriverPositionForRouteUpdate == null ||
        Geolocator.distanceBetween(
              _lastDriverPositionForRouteUpdate!.latitude,
              _lastDriverPositionForRouteUpdate!.longitude,
              _driverLocation!.latitude,
              _driverLocation!.longitude,
            ) >
            _routeUpdateDistanceThreshold) {
      _lastDriverPositionForRouteUpdate = _driverLocation;
      _traceDriverRoute();
    }
  }

  Future<void> _traceDriverRoute() async {
    if (_driverLocation != null && _startLocation != null) {
      try {
        await _driverTravelLocalDataSource.getRoute(
            _driverLocation!, _endLocation!); // Actualiza la ruta del conductor hacia el destino
        String encodedPoints = await _driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _driverTravelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.removeWhere((polyline) => polyline.polylineId.value == 'driver_route');
          _polylines.add(Polyline(
            polylineId: PolylineId('driver_route'),
            points: polylineCoordinates,
            color: Colors.red,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta del conductor: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _startLocation ?? _center,
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.info_outline, size: 40),
                onPressed: () {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    title: 'Información del Viaje',
                    text: widget.travelList.isNotEmpty
                        ? 'Cliente: ${widget.travelList[0].client}\nCosto: ${widget.travelList[0].cost}'
                        : 'Sin información de cliente',
                    confirmBtnText: 'Cerrar',
                  );
                },
              ),
            ),
            Positioned(
              bottom: 80,
              right: 10,
              child: ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.buttonColormap,
                ),
                child: Text('Iniciar Viaje'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
