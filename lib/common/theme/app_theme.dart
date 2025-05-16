import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:rayo_taxi/common/app/splash_screen.dart';
import 'package:rayo_taxi/common/routes/router.dart';
import 'package:rayo_taxi/main.dart';

class AppThemeCustom {
     final ColorScheme colorScheme = ColorScheme.fromSwatch().copyWith(
      primary: Color.fromARGB(255, 254, 255, 255),
      secondary: Color(0xFFEFC300),
    );

    ThemeData getTheme({required ThemeMode mode, required BuildContext context}) {
  return ThemeData(
        primaryColor: Color(0xFF3F3F3F),
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
        textTheme: TextTheme(
            displayLarge: TextStyle(fontSize: 16, color: Colors.green),
            titleMedium: TextStyle(fontSize: 16, color: Colors.yellow),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
            bodyMedium: TextStyle(fontSize: 12, color: Colors.grey[600]),
            bodySmall: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            )),
            
      );
      }
}