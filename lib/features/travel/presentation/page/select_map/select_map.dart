import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/midireccion/midireccion_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/travel_route.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';

class SelectMap extends StatefulWidget {
  @override
  _SelectMapState createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final CurrentTravelGetx travelAlertGetx = Get.find<CurrentTravelGetx>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final state = travelAlertGetx.state.value;
        if (state is TravelAlertLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is TravelAlertLoaded) {
          return MapContent(travelList: state.travels);
        } else if (state is TravelAlertFailure) {
          return MapContent(travelList: []);
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }),
    );
  }
}

class MapContent extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  MapContent({required this.travelList});

  @override
  _MapContentState createState() => _MapContentState();
}

Future<void> _checkTravelId() async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  String travelString = sharedPreferences.getString('getalltravelid') ?? "";

  if (travelString.isNotEmpty) {
    try {
      Map<String, dynamic> travelMap = jsonDecode(travelString);
      TravelAlertModel travelAlert = TravelAlertModel.fromJson(travelMap);
      Future.delayed(Duration.zero, () {
        navigatorKey.currentState!.pushNamed(
          RoutesNames.acceptTravelPage,
          arguments: {'idTravel': travelAlert.id ?? 0},
        );
      });
    } catch (e) {
      print("Error al cargar el viaje desde SharedPreferences: $e");
    }
  }
}

class _MapContentState extends State<MapContent> with WidgetsBindingObserver {
  SocketDriverDataSource? socketDriver;
  bool _hasActiveTravel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTravelState();
  }

  @override
  void didUpdateWidget(MapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verificar si cambió el estado de los viajes
    if (oldWidget.travelList.isEmpty != widget.travelList.isEmpty) {
      _updateTravelState();
    }
  }

  void _updateTravelState() {
    bool hasActiveTravel = widget.travelList.isNotEmpty;
    
    // Si el estado cambió
    if (_hasActiveTravel != hasActiveTravel) {
      _hasActiveTravel = hasActiveTravel;
      
      if (hasActiveTravel) {
        // Si ahora hay viajes activos, asegurarse de que no haya socket activo
        socketDriver?.dispose();
        socketDriver = null;
      } else {
        // Si ya no hay viajes activos, desconectar el socket
        _disconnectSocket();
      }
    }
  }

  void _disconnectSocket() {
    // Crear una nueva instancia solo para desconectarla correctamente y limpiar recursos
    if (socketDriver == null) {
      socketDriver = SocketDriverDataSourceImpl();
    }
    
    print("MapContent: Desconectando socket porque no hay viajes activos");
    socketDriver?.disconnect();
    
    // Usar dispose para cerrar completamente y liberar recursos
    Future.delayed(Duration(milliseconds: 500), () {
      if (socketDriver != null) {
        print("MapContent: Limpiando recursos del socket");
        socketDriver?.dispose();
        socketDriver = null;
      }
    });
  }

  @override
  void dispose() {
    _disconnectSocket();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver a primer plano, verificar si hay que desconectar el socket
      if (!_hasActiveTravel) {
        _disconnectSocket();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.travelList.isNotEmpty) {
      AuthService().clearCurrenttravel();
      return TravelRoute(travelList: widget.travelList);
    } else {
      _checkTravelId();
      return MidireccionPage();
    }
  }
}