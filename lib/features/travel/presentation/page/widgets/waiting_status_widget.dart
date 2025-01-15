import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/travel_route_controller.dart';

class WaitingStatusWidget extends StatelessWidget {
  final bool isIdStatusSix;
  final String waitingFor;
  final NotificationService notificationService;
  final TravelRouteController controller;

  const WaitingStatusWidget({
    Key? key,
    required this.isIdStatusSix,
    required this.waitingFor,
    required this.notificationService,
    required this.controller,
  }) : super(key: key);

  void _showConfirmationDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: '¿Estás seguro?',
      text: '¿Deseas rechazar esta oferta?',
      confirmBtnText: 'Sí, rechazar',
      cancelBtnText: 'No, cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        controller.CancelTravel(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isIdStatusSix) {
      return SizedBox.shrink();
    }

    if (waitingFor == "1") {
      return _buildWaitingMessage(
        'Esperando respuesta del cliente',
        Colors.orangeAccent,
        context
      );
    } else if (waitingFor == "2") {
      return _buildCounterOfferMessage(context);
    }

    return SizedBox.shrink();
  }

  Widget _buildWaitingMessage(String message, Color color, BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () {
              _showConfirmationDialog(context);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
               
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterOfferMessage(BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Esperando tu contra oferta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () {
                    notificationService.showNewPriceDialog(context);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.message,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}