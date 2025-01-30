// socket_driver_data_source.dart
import 'dart:async';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketDriverDataSourceImpl {
  late IO.Socket socket;
  StreamController<Map<String, dynamic>>? _locationController;
  Timer? _pingTimer;
  bool _intentionalDisconnect = false;
          String _baseUrl = AppConstants.serverBase;

  String? get socketId => socket.id;

  Stream<Map<String, dynamic>> get locationUpdates {
    _locationController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _locationController!.stream;
  }
  
  SocketDriverDataSourceImpl() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'reconnection': true,
      'reconnectionAttempts': 10000,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'timeout': 20000,
      'pingInterval': 5000,
      'pingTimeout': 10000
    });

    socket.onConnect((_) {
      print('Conectado al servidor de Socket.IO con ID: ${socket.id}');
      _startPingTimer();
    });

    socket.onDisconnect((_) {
      print('Desconectado del servidor');
      if (!_intentionalDisconnect) {
        _reconnect();
      }
    });

    socket.onError((error) {
      print('Error de socket: $error');
      if (!_intentionalDisconnect) {
        _reconnect();
      }
    });

    socket.on('driver_location_update', (data) {
      try {
        if (_locationController != null && !_locationController!.isClosed) {
          _locationController!.add(data as Map<String, dynamic>);
        }
      } catch (e) {
        print('Error al procesar datos del socket: $e');
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (socket.connected) {
        socket.emit('ping');
      }
    });
  }

  void _reconnect() {
    Future.delayed(Duration(seconds: 1), () {
      if (!socket.connected && !_intentionalDisconnect) {
        print('Intentando reconectar...');
        socket.connect();
      }
    });
  }

  bool isConnected() {
    return socket.connected;
  }

  void connect() {
    _intentionalDisconnect = false;
    if (!isConnected()) {
      socket.connect();
    }
  }

  void joinTravel(String idTravel) {
    if (isConnected()) {
      socket.emit('join_travel', {'id_travel': idTravel});
    } else {
      connect();
      Future.delayed(Duration(milliseconds: 500), () {
        socket.emit('join_travel', {'id_travel': idTravel});
      });
    }
  }

  void updateLocation(String idTravel, Map<String, dynamic> location) {
    if (isConnected()) {
      socket.emit('update_driver_location', {
        'id_travel': idTravel,
        'location': location
      });
    } else {
      connect();
      Future.delayed(Duration(milliseconds: 500), () {
        socket.emit('update_driver_location', {
          'id_travel': idTravel,
          'location': location
        });
      });
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    socket.disconnect();
  }

  void dispose() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    if (_locationController != null && !_locationController!.isClosed) {
      _locationController!.close();
      _locationController = null;
    }
    socket.dispose();
  }
}

/*// lib/data/datasources/socket_driver_datasource.dart
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
  
  @override
  String? get socketId => socket.id;

  @override
  Stream<Map<String, dynamic>> get locationUpdates => _locationController.stream;
  
  SocketDriverDataSourceImpl() {
    socket = IO.io('http://localhost:3010', <String, dynamic>{
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

// lib/presentation/pages/socket_test_page.dart
import 'package:flutter/material.dart';
import 'dart:async';

class SocketTestPage extends StatefulWidget {
  const SocketTestPage({super.key});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  final socketDriver = SocketDriverDataSourceImpl();
  final String testTravelId = "test_travel_123";
  String? currentSocketId;
  Map<String, dynamic>? lastLocation;
  StreamSubscription? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    socketDriver.connect();
    
    // Actualizamos el ID después de un breve delay para asegurar la conexión
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentSocketId = socketDriver.socketId;
      });
    });

    // Nos suscribimos a las actualizaciones de ubicación
    _locationSubscription = socketDriver.locationUpdates.listen((location) {
      setState(() {
        lastLocation = location;
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    socketDriver.disconnect();
    super.dispose();
  }

  void _joinTravel() {
    socketDriver.joinTravel(testTravelId);
  }

  void _sendLocation() {
    final testLocation = {
      'latitude': 19.4326,
      'longitude': -99.1332,
      'speed': 30.5,
      'bearing': 180.0
    };
    socketDriver.updateLocation(testTravelId, testLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Socket.IO'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Socket ID: ${currentSocketId ?? "Conectando..."}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'ID del viaje: $testTravelId',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Última ubicación recibida:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (lastLocation != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latitud: ${lastLocation!['latitude']}'),
                    Text('Longitud: ${lastLocation!['longitude']}'),
                    Text('Velocidad: ${lastLocation!['speed']}'),
                    Text('Dirección: ${lastLocation!['bearing']}'),
                  ],
                ),
              )
            else
              const Text('Sin datos de ubicación'),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _joinTravel,
                    child: const Text('Unirse al viaje'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendLocation,
                    child: const Text('Enviar ubicación'),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Socket.IO Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SocketTestPage(),
    );
  }
} */