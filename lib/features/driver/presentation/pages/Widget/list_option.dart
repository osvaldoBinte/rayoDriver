// lib/features/client/presentation/widgets/list_option.dart

import 'package:flutter/material.dart';

class ListOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final Color? cardColor;

  const ListOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onPressed,
    this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor ?? Colors.white, // Permitir especificar color
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onPressed ?? () {},
        leading: Icon(icon, color: Colors.black, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
