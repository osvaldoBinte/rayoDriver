import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';

class LoginDriverPage extends StatelessWidget {
  final LogindriverGetx _driverGetx = Get.find<LogindriverGetx>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColorLogin,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      'assets/images/logo-new.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: screenHeight * 0.29,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.card,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'INICIAR SESIÓN',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: TextFormField(
                                  controller: _driverGetx.emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .blueAccent),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .fillColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          
                                          .primaryColor),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su correo electrónico';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(value)) {
                                      return 'Por favor ingrese un correo electrónico válido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Obx(() {
                                  return TextFormField(
                                    controller:
                                        _driverGetx.passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      labelStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .blueAccent),
                                      filled: true,
                                      fillColor: Theme.of(context)
                                          .colorScheme
                                          .fillColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _driverGetx.obscureText.value
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .blueAccent,
                                        ),
                                        onPressed: _driverGetx
                                            .togglePasswordVisibility,
                                      ),
                                    ),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryColor),
                                    obscureText:
                                        _driverGetx.obscureText.value,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese su contraseña';
                                      }
                                      return null;
                                    },
                                  );
                                }),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Obx(() {
                                  return ElevatedButton(
                                    onPressed: _driverGetx.isLoading.value
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _driverGetx.login();
                                            }
                                          },
                                    child: _driverGetx.isLoading.value
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SpinKitFadingCube(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .textButton,
                                                size: 24.0,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Cargando...',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .textButton,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .textButton,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttonColor,
                                      minimumSize: Size(
                                          double.infinity, 50), // Ancho completo
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (_driverGetx.isLoading.value) {
              return Container(
                color:Theme.of(context).primaryColor.withOpacity(0.5),
                child: Center(
                  child: SpinKitFadingCube(
                    color: Theme.of(context).colorScheme.primary,
                    size: 50.0,
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
