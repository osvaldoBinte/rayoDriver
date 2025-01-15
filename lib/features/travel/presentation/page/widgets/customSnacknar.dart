import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';

class CustomSnackBar {
  static void showSuccess(String title, String message) {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.snackbar(
      title,
      message,
      backgroundColor: Get.theme.colorScheme.Success,
          colorText: Get.theme.colorScheme.snackBartext2,

      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 3),
    );
  }

static void showError(String title, String message) {
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }
  
  final colorScheme = Get.theme.colorScheme;

  Get.snackbar(
    title,
    message,
    backgroundColor: colorScheme.error, 
    colorText: colorScheme.snackBartext,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 3),
  );
}

 
}