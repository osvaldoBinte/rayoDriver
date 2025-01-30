import 'dart:ui';

import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
enum CustomAlertType { info, confirm, warning, success, error }

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? imagePath;
  final CustomAlertType type;
  final Widget? customWidget;
  // Campos adicionales para el tipo info
  final String? driverName;
  final String? rating;
  final String? carModel;
  final String? licensePlate;
  final int? totalTrips;
  final String? profileImageUrl;
 
  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.imagePath,
    required this.type,
    this.customWidget,
    this.driverName,
    this.rating,
    this.carModel,
    this.licensePlate,
    this.totalTrips,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: type == CustomAlertType.info
          ? _buildInfoDialog(context)
          : _buildStandardDialog(context),
    );
  }

  Widget _buildInfoDialog(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Foto de perfil con calificación
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Text(driverName?.substring(0, 1).toUpperCase() ?? 'U')
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(rating ?? '0.0'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              // Información del conductor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      licensePlate ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${totalTrips ?? 0} viajes',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Información del vehículo
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  imagePath ?? 'assets/images/viajes/taxi.png',
                  width: 100,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    carModel ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Botón de cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onConfirm ?? () => Navigator.of(context).pop(),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildStandardDialog(BuildContext context) {
  Color headerColor;
  Widget headerContent;
  
  switch (type) {
    case CustomAlertType.warning:
      headerColor = Theme.of(context).colorScheme.secondary;
      headerContent = const AnimatedDollarSigns();
      break;
    case CustomAlertType.confirm:
    default:
      headerColor = Theme.of(context).colorScheme.Aleradmiration  ;
      headerContent = const AnimatedExclamationMark();
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Center(
            child: headerContent,
          ),
        ),
        // Content section
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (title.isNotEmpty) Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (title.isNotEmpty) const SizedBox(height: 12),
              if (message.isNotEmpty) Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (message.isNotEmpty) const SizedBox(height: 24),
              if (customWidget != null) customWidget!,
              if ((confirmText.isNotEmpty || cancelText?.isNotEmpty == true) &&
                  customWidget == null)
                _buildButtons(context),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildButtons(BuildContext context) {
  return Row(
    children: [
      // "Confirmar" button (ahora en gris)
      Expanded(
        child: TextButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      // "Cancelar" button (ahora en azul)
      Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: Text(
            cancelText ?? 'Cancelar',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}
}

class AnimatedExclamationMark extends StatefulWidget {
  const AnimatedExclamationMark({Key? key}) : super(key: key);

  @override
  _AnimatedExclamationMarkState createState() => _AnimatedExclamationMarkState();
}

class _AnimatedExclamationMarkState extends State<AnimatedExclamationMark>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white.withOpacity(0.7),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle(
        speed: random.nextDouble() * 2 + 1,
        theta: random.nextDouble() * math.pi * 2,
        radius: random.nextDouble() * 20 + 10,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Particles
        ..._buildParticles(),
        // Main exclamation mark
        AnimatedBuilder(
          animation: Listenable.merge([_mainController, _colorAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Text(
                  '¡',
                  style: TextStyle(
                    color: _colorAnimation.value,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = _particleController.value;
          final opacity = (1 - progress).clamp(0.0, 1.0);
          final scale = (1 - progress * 0.5).clamp(0.0, 1.0);
          
          return Positioned(
            left: math.cos(particle.theta) * particle.radius * progress * 2,
            top: math.sin(particle.theta) * particle.radius * progress * 2,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

class Particle {
  final double speed;
  final double theta;
  final double radius;

  Particle({
    required this.speed,
    required this.theta,
    required this.radius,
  });
}
void showCustomAlert({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  String? imagePath,
  required CustomAlertType type,
  Widget? customWidget,
  String? driverName,
  String? rating,
  String? carModel,
  String? licensePlate,
  int? totalTrips,
  String? profileImageUrl,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return WillPopScope(
        onWillPop: () async => false,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: CustomAlertDialog(
              title: title,
              message: message,
              confirmText: confirmText,
              cancelText: cancelText,
              onConfirm: onConfirm,
              onCancel: onCancel,
              imagePath: imagePath,
              type: type,
              customWidget: customWidget,
              driverName: driverName,
              rating: rating,
              carModel: carModel,
              licensePlate: licensePlate,
              totalTrips: totalTrips,
              profileImageUrl: profileImageUrl,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: animation.value * 3,
          sigmaY: animation.value * 3,
        ),
        child: child,
      );
    },
  );
}
class AnimatedDollarSigns extends StatefulWidget {
  const AnimatedDollarSigns({Key? key}) : super(key: key);

  @override
  _AnimatedDollarSignsState createState() => _AnimatedDollarSignsState();
}

class _AnimatedDollarSignsState extends State<AnimatedDollarSigns>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late List<AnimationController> _dollarControllers;
  final int numberOfDollars = 3;
  final List<MoneyParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _generateParticles();
    _startAnimation();
  }

  void _initializeControllers() {
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _dollarControllers = List.generate(
      numberOfDollars,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      ),
    );
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(MoneyParticle(
        speed: random.nextDouble() * 2 + 1,
        theta: random.nextDouble() * math.pi * 2,
        radius: random.nextDouble() * 30 + 15,
        type: random.nextBool() ? ParticleType.sparkle : ParticleType.coinBit,
      ));
    }
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < _dollarControllers.length; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 200));
        _dollarControllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 400));
        _dollarControllers[i].reverse();
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ..._buildParticles(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(numberOfDollars, (index) {
            return _buildAnimatedDollar(index);
          }),
        ),
      ],
    );
  }

  Widget _buildAnimatedDollar(int index) {
    return AnimatedBuilder(
      animation: _dollarControllers[index],
      builder: (context, child) {
        final bounce = Curves.elasticOut.transform(_dollarControllers[index].value);
        final rotation = math.sin(_mainController.value * math.pi * 2) * 0.1;
        
        return Transform.translate(
          offset: Offset(0, -20 * bounce),
          child: Transform.rotate(
            angle: rotation,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1500),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale * (1 + bounce * 0.2),
                  child: child,
                );
              },
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                      const Color(0xFFFFD700),
                    ],
                    stops: [0.0, 0.5, 1.0],
                    transform: GradientRotation(_mainController.value * math.pi * 2),
                  ).createShader(bounds);
                },
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = _particleController.value;
          final opacity = (1 - progress).clamp(0.0, 1.0);
          final scale = (1 - progress * 0.5).clamp(0.0, 1.0);
          
          return Positioned(
            left: math.cos(particle.theta) * particle.radius * progress * 2,
            top: math.sin(particle.theta) * particle.radius * progress * 2,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: particle.type == ParticleType.sparkle
                    ? _buildSparkle()
                    : _buildCoinBit(),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildSparkle() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBit() {
    return Container(
      width: 6,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.8),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    for (var controller in _dollarControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class MoneyParticle {
  final double speed;
  final double theta;
  final double radius;
  final ParticleType type;

  MoneyParticle({
    required this.speed,
    required this.theta,
    required this.radius,
    required this.type,
  });
}

enum ParticleType { sparkle, coinBit }