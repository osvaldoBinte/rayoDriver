import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';

class CarInfoDisplay extends StatelessWidget {
  final Driver driver;

  const CarInfoDisplay({Key? key, required this.driver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.card,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: _buildProfileImage(driver.path_photo, driver.name.toString()),
                        ),
                        
                        const SizedBox(height: 24),
                        _buildInfoField('Marca', driver.brand ?? ''),
                        _buildInfoField('Año', driver.year ?? ''),
                        _buildInfoField('Modelo', driver.model ?? ''),
                        _buildInfoField('Placas ', driver.plates ?? ''),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildProfileImage(String? pathPhoto, String clientName) {
  if (pathPhoto != null && pathPhoto.isNotEmpty) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Borde redondeado
        border: Border.all(
          color: Colors.grey[300]!,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Mismo radio para el recorte
        child: Image.network(
          pathPhoto,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(clientName);
          },
        ),
      ),
    );
  } else {
    return _buildFallbackAvatar(clientName);
  }
}

Widget _buildFallbackAvatar(String clientName) {
  return Container(
    width: 200,
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20), // Borde redondeado
      color: Colors.blue,
      border: Border.all(
        color: Colors.grey[300]!,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Center(
      child: Text(
        clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 60,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}


  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 1,
              ),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}