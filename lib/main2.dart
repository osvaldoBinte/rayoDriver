// lib/data/datasources/socket_driver_datasource.dart
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rayo_taxi/common/settings/enviroment.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/constants/constants.dart';



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
 socket = IO.io(_baseUrl, <String, dynamic>{
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

class SocketTestPage extends StatefulWidget {
  const SocketTestPage({super.key});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  final socketDriver = SocketDriverDataSourceImpl();
  final String testTravelId = "123";
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
String enviromentSelect = Enviroment.development.value; 

void main() async {
    await dotenv.load(fileName: enviromentSelect);

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
}