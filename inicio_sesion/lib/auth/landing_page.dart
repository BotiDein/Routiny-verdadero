import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import 'login_page.dart';
import 'register_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Advertencia'),
            content: const Text(
              'Si se borra la app, los datos no quedarán guardados. ¿Seguro que quieres seguir?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              TextButton(
                child: const Text('Continuar'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await FirebaseAuth.instance.signInAnonymously();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.7;
    final buttonHeight = screenHeight * 0.06;
    final fontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: Colors.cyan[50],
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: screenWidth * 0.3,
                    color: Colors.blue,
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // Botón Invitado
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                      ),
                      onPressed: () => _showGuestDialog(context),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '¿Quieres iniciar sesión como invitado?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  Text('o', style: TextStyle(fontSize: fontSize)),
                  SizedBox(height: screenHeight * 0.02),

                  // Botón Correo
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '¿Quieres iniciar sesión con un correo?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                    child: Text(
                      '¿No te has registrado aun?\nDa clic aquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: const Color(0xFF0052A9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
