import 'package:flutter/material.dart';
import 'dart:async';

import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';

class SocketTestPage extends StatefulWidget {
  const SocketTestPage({super.key});

  @override
  State<SocketTestPage> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  final socketDriver = SocketDriverDataSourceImpl();
  final String testTravelId = "1059";
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
}