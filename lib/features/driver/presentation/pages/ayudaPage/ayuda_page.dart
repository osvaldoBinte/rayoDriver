import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'dart:io' show Platform;

class AyudaPage extends StatelessWidget {
  final Driver driver;
  static const platform = MethodChannel('com.tuapp/whatsapp');
  static const platformPhone = MethodChannel('com.tuapp/phone');

  const AyudaPage({
    Key? key,
    required this.driver,
  }) : super(key: key);

  void _abrirWhatsApp(BuildContext context) async {
    final telefono = driver.phone_support?.replaceAll(RegExp(r'[^\d]'), '');
    final whatsappUrl = 'https://wa.me/+ 52$telefono?text=${'Hola!! necesito ayuda'}';
    
    try {
      Uri uri = Uri.parse(whatsappUrl);
      await launchUrlNative(uri);
    } catch (e) {
      print('hola $e');    
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp. Asegúrate de tenerlo instalado.'),
          ),
        );
      }
    }
  }

  void _hacerLlamada(BuildContext context) async {
    final phone_support = driver.phone_support?.replaceAll(RegExp(r'[^\d]'), '');
    final phoneUrl = 'tel:+52$phone_support';
    
    try {
      Uri uri = Uri.parse(phoneUrl);
      await launchPhoneCall(uri);
    } catch (e) {
      print('Error llamada: $e');    
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la llamada.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.button,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => _hacerLlamada(context),
              icon: const Icon(
                Icons.phone,
                size: 24,
              ),
              label: const Text(
                'Contactar por Teléfono',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.whatsApp,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => _abrirWhatsApp(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/whatsApp.png',
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Contactar por WhatsApp',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Future<void> launchUrlNative(Uri uri) async {
  final String uriString = uri.toString();
  
  try {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.tuapp/whatsapp');
      await platform.invokeMethod('openWhatsApp', {'url': uriString});
    } else if (Platform.isIOS) {
      const platform = MethodChannel('com.tuapp/whatsapp');
      await platform.invokeMethod('openWhatsApp', {'url': uriString});
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  } on PlatformException catch (e) {
    throw Exception('Error al abrir WhatsApp: ${e.message}');
  }
}

Future<void> launchPhoneCall(Uri uri) async {
  final String uriString = uri.toString();
  
  try {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.tuapp/phone');
      await platform.invokeMethod('makePhoneCall', {'url': uriString});
    } else if (Platform.isIOS) {
      const platform = MethodChannel('com.tuapp/phone');
      await platform.invokeMethod('makePhoneCall', {'url': uriString});
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  } on PlatformException catch (e) {
    throw Exception('Error al hacer la llamada: ${e.message}');
  }
}