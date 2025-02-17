// emergency_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ayuda_controller.dart';


class ProgressArcPainter extends CustomPainter {
  final double progress;
  final bool isPressed;

  ProgressArcPainter({
    required this.progress,
    required this.isPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPressed) return;

    // Ajustamos el rectángulo para que siga el borde redondeado del botón
    final double strokeWidth = 4.0;
    final double padding = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      padding, 
      padding, 
      size.width - (padding * 2), 
      size.height - (padding * 2)
    );

    // Dibujamos el borde completo en gris claro
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(30)),
      backgroundPaint,
    );

    // Dibujamos el progreso en blanco
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Calculamos el ángulo de barrido para el progreso
    final startAngle = -90.0 * (3.14159 / 180.0); // Comenzamos desde arriba
    final sweepAngle = 360.0 * (3.14159 / 180.0) * progress;

    // Dibujamos el arco de progreso
    Path progressPath = Path();
    progressPath.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(30)));

    canvas.drawPath(
      dashPath(
        progressPath,
        progress: progress,
        dashArray: CircularIntervalList<double>([sweepAngle, 0.0]),
      ),
      progressPaint,
    );
  }

  Path dashPath(
    Path path, {
    required double progress,
    required CircularIntervalList<double> dashArray,
  }) {
    final Path dashPath = Path();
    final double length = progress * path.computeMetrics().first.length;
    
    path.computeMetrics().first.extractPath(0, length).computeMetrics().forEach((metric) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len), 
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    });
    
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPressed != isPressed;
  }
}

// Clase auxiliar para crear una lista circular de valores
class CircularIntervalList<T> {
  final List<T> _values;
  int _index = 0;

  CircularIntervalList(this._values);

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
