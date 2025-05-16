// emergency_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;

class EmergencyController extends GetxController with GetSingleTickerProviderStateMixin {
  static const platformPhone = MethodChannel('com.tuapp/phone');
  
  late AnimationController animationController;
  final isPressed = false.obs;
  final holdDuration = 1; // duración en segundos

  EmergencyController();

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: holdDuration),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        makeEmergencyCall();
      }
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void onEmergencyTapDown() {
    isPressed.value = true;
    animationController.forward();
  }

  void onEmergencyTapUp() {
    isPressed.value = false;
    animationController.reset();
  }

  void onEmergencyTapCancel() {
    isPressed.value = false;
    animationController.reset();
  }

  Future<void> makeEmergencyCall() async {
    String supportPhone = '352 163 0745';
    final phoneUrl = 'tel:+52${supportPhone.replaceAll(RegExp(r'[^\d]'), '')}';
    
    try {
      Uri uri = Uri.parse(phoneUrl);
      if (Platform.isAndroid || Platform.isIOS) {
        await platformPhone.invokeMethod('makeEmergencyCall', {'url': uri.toString()});
      }
    } on PlatformException catch (e) {
      String errorMessage = 'No se pudo realizar la llamada de emergencia.';
      if (e.code == 'PERMISSION_DENIED') {
        errorMessage = 'Se requiere permiso para realizar llamadas de emergencia.';
      }
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo realizar la llamada de emergencia.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}