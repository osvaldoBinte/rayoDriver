

// emergency_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/ayudaPage/ProgressArcPainter.dart';
import 'ayuda_controller.dart';
class EmergencyButton extends GetView<AyudaController> {
  const EmergencyButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.onEmergencyTapDown(),
      onTapUp: (_) => controller.onEmergencyTapUp(),
      onTapCancel: () => controller.onEmergencyTapCancel(),
      child: AnimatedBuilder(
        animation: controller.animationController,
        builder: (context, child) {
          return Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Theme.of(context).colorScheme.emergency,
              boxShadow: [
                BoxShadow(
                  color:  Theme.of(context).colorScheme.emergency.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() => CustomPaint(
              painter: ProgressArcPainter(
                progress: controller.animationController.value,
                isPressed: controller.isPressed.value,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    Icons.local_hospital,  
                    color: Theme.of(context).colorScheme.buttontext,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                   Text(
                    'EMERGENCIA',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.buttontext,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            )),
          );
        },
      ),
    );
  }
}
