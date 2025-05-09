import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/landing_page.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera 3 segundos antes de navegar a la siguiente pantalla
    Timer(const Duration(seconds: 3), () {
      // Verificar si hay un usuario autenticado
      final user = FirebaseAuth.instance.currentUser;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user != null ? const MainScreen() : const LandingPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla para usar medidas proporcionales
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFDFFFFB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: screenWidth * 0.6,
              height: screenHeight * 0.3,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si no se encuentra la imagen
                return Icon(
                  Icons.calendar_today,
                  size: screenWidth * 0.4,
                  color: const Color(0xFF0052A9),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.04),
            const Text(
              'Routiny',
              style: TextStyle(
                fontFamily: 'RobotoBold',
                fontSize: 48,
                color: Color(0xFF0052A9),
              ),
            ),
            SizedBox(height: screenHeight * 0.18),
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052A9)),
            ),
          ],
        ),
      ),
    );
  }
}