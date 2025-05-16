// emergency_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'emergency_controller.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmergencyController());

    return GestureDetector(
      onTapDown: (_) => controller.onEmergencyTapDown(),
      onTapUp: (_) => controller.onEmergencyTapUp(),
      onTapCancel: () => controller.onEmergencyTapCancel(),
      child: AnimatedBuilder(
        animation: controller.animationController,
        builder: (context, child) {
          return ClipOval(
            child: Container(
              width: 40,
              height: 40,
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
              child: Obx(() => Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.isPressed.value)
                    CircularProgressIndicator(
                      value: controller.animationController.value,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 4,
                    ),
                  Icon(
                    Icons.local_hospital,
                    color: Theme.of(context).colorScheme.buttontext,
                    size: 20,
                  ),
                ],
              )),
            ),
          );
        },
      ),
    );
  }
}