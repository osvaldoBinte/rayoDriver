import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';

import './emergency_controller.dart';

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

    final double strokeWidth = 4.0;
    final double padding = strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - padding * 2) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -90.0 * (3.14159 / 180.0);
    final sweepAngle = 360.0 * (3.14159 / 180.0) * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPressed != isPressed;
  }
}

class EmergencyButton extends StatelessWidget {
  EmergencyButton({Key? key}) : super(key: key);

  // Inicializamos el controller aquí
  final EmergencyController controller = Get.put(EmergencyController());

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 40.0; // Reducido a 40 para mantener el tamaño que tenías

    return GestureDetector(
      onTapDown: (_) => controller.onEmergencyTapDown(),
      onTapUp: (_) => controller.onEmergencyTapUp(),
      onTapCancel: () => controller.onEmergencyTapCancel(),
      child: AnimatedBuilder(
        animation: controller.animationController,
        builder: (context, child) {
          return Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.emergency,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.emergency.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() => CustomPaint(
              painter: ProgressArcPainter(
                progress: controller.animationController.value,
                isPressed: controller.isPressed.value,
              ),
              child: Center(
                child: Icon(
                  Icons.local_hospital,
                  color: Theme.of(context).colorScheme.buttontext,
                  size: 20,
                ),
              ),
            )),
          );
        },
      ),
    );
  }
}