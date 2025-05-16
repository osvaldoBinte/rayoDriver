import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class HomeController extends GetxController {
  // Variable observable para el índice seleccionado
  final RxInt selectedIndex = 0.obs;
  DateTime? lastBackPressTime;

  @override
  void onInit() {
    super.onInit();
    requestInitialPermissions();
    
    // Verificar argumentos de navegación
    try {
      if (Get.arguments != null && Get.arguments['selectedIndex'] != null) {
        int index = Get.arguments['selectedIndex'];
        print('Inicializando HomeController con índice: $index (desde argumentos)');
        selectedIndex.value = index;
      }
    } catch (e) {
      print('Error al obtener argumentos: $e');
    }
  }

  @override
  void onClose() {
    // Limpieza de recursos si es necesario
    print('HomeController onClose llamado');
    super.onClose();
  }

  Future<void> requestInitialPermissions() async {
    try {
      await requestNotificationPermission();
      await requestPhonePermission();
    } catch (e) {
      print('Error al solicitar permisos: $e');
    }
  }

  void setIndex(int index) {
    print('Cambiando índice de ${selectedIndex.value} a $index');
    selectedIndex.value = index;
    setStatusBarColor();
  }

  Future<bool> handleBackButton(int initialIndex) async {
    if (selectedIndex.value != initialIndex) {
      selectedIndex.value = initialIndex;
      return false;
    }
    
    if (lastBackPressTime == null || 
        DateTime.now().difference(lastBackPressTime!) > Duration(seconds: 2)) {
      lastBackPressTime = DateTime.now();
      Get.showSnackbar(
        GetSnackBar(
          message: 'Presiona nuevamente para salir',
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  void setStatusBarColor() {
    try {
      final context = Get.context!;
      final statusBarColor = Theme.of(context).primaryColor;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ));
    } catch (e) {
      print('Error al establecer el color de la barra de estado: $e');
    }
  }

  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      var result = await Permission.notification.request();
      if (result.isPermanentlyDenied) {
      }
    }
  }

  Future<void> requestPhonePermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      var result = await Permission.phone.request();
      if (result.isPermanentlyDenied) {
      }
    }
  }
}