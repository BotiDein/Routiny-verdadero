import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Agregar esta importación
import '../screens/main_screen.dart';
import 'login_page.dart';
import '../auth/landing_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
  if (!mounted) return;

  if (passwordController.text != confirmPasswordController.text) {
    setState(() => error = 'Las contraseñas no coinciden');
    return;
  }

  setState(() {
    isLoading = true;
    error = '';
  });

  try {
    // Crear el usuario con Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    
    // Guardar SOLO el nombre y email en Firestore
    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      // NO guardar la contraseña aquí
    });

    // También actualizar el displayName en el perfil de Auth
    await userCredential.user!.updateDisplayName(nameController.text.trim());

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  } on FirebaseAuthException catch (e) {
  if (!mounted) return;

  String errorMessage;

  switch (e.code) {
    case 'email-already-in-use':
      errorMessage = 'Este correo ya está en uso.';
      break;
    case 'invalid-email':
      errorMessage = 'El correo electrónico no es válido.';
      break;
    case 'operation-not-allowed':
      errorMessage = 'La creación de cuentas está deshabilitada.';
      break;
    case 'weak-password':
      errorMessage = 'La contraseña es demasiado débil.';
      break;
    default:
      errorMessage = 'Ocurrió un error: ${e.message}';
  }

  setState(() => error = errorMessage);
}
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.7;
    final buttonHeight = screenHeight * 0.06;
    final fontSize = screenWidth * 0.04;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.015,
    );

    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LandingPage()),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo y nombre de la app
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: screenWidth * 0.4,
                      height: screenWidth * 0.4,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          size: screenWidth * 0.4,
                          color: Colors.grey,
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Text(
                      'Routiny',
                      style: TextStyle(
                        fontFamily: 'RobotoBold',
                        fontSize: screenWidth * 0.12,
                        color: const Color(0xFF0052A9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03), // Reducido para más espacio

                // Campo para el nombre del usuario
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nombre',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Campo para el correo electrónico
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Correo electrónico',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Campo para la contraseña
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Campo para confirmar la contraseña
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirmar contraseña',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03), // Reducido para más espacio

                // Botón de registro
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    onPressed: isLoading ? null : register,
                    child: Text(
                      'Registrarse',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),

                // Mostrar error si hay alguno
                if (error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.02),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: fontSize * 0.9,
                      ),
                    ),
                  ),

                // Enlace para ir al login
                SizedBox(height: screenHeight * 0.03),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text(
                    '¿Ya tienes una cuenta?\nDa clic aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: const Color(0xFF0052A9),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
