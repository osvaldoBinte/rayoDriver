
// lib/data/datasources/socket_driver_datasource.dart
import 'dart:async';

import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

abstract class SocketDriverDataSource {
  void connect();
  void joinTravel(String idTravel);
  void updateLocation(String idTravel, Map<String, dynamic> location);
  void disconnect();
  String? get socketId;
  Stream<Map<String, dynamic>> get locationUpdates;
}

class SocketDriverDataSourceImpl implements SocketDriverDataSource {
  late IO.Socket socket;
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
          String _baseUrl = AppConstants.serverBase;

  @override
  String? get socketId => socket.id;

  @override
  Stream<Map<String, dynamic>> get locationUpdates => _locationController.stream;
  
  SocketDriverDataSourceImpl() {
    socket = IO.io('$_baseUrl', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Escuchar eventos
    socket.onConnect((_) {
      print('Conectado al servidor de Socket.IO con ID: ${socket.id}');
    });

    socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });

    socket.on('driver_location_update', (data) {
      print('Nueva ubicación recibida: $data');
      _locationController.add(data as Map<String, dynamic>);
    });
  }

  @override
  void connect() {
    socket.connect();
  }

  @override
  void joinTravel(String idTravel) {
    socket.emit('join_travel', {'id_travel': idTravel});
  }

  @override
  void updateLocation(String idTravel, Map<String, dynamic> location) {
    socket.emit('update_driver_location', {
      'id_travel': idTravel,
      'location': location
    });
  }

  @override
  void disconnect() {
    _locationController.close();
    socket.disconnect();
  }
}
