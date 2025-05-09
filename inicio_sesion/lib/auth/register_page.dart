import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!mounted) return;

    // Validar que las contraseñas coincidan
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message ?? 'Error');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calcular tamaños relativos
    final buttonWidth = screenWidth * 0.7;
    final buttonHeight = screenHeight * 0.06;
    final fontSize = screenWidth * 0.04;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.015,
    );
    
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(
                  Icons.person_add,
                  size: screenWidth * 0.3,
                  color: Colors.blue,
                ),
                SizedBox(height: screenHeight * 0.04),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    filled: true,
                    fillColor: Colors.cyanAccent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.cyanAccent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    filled: true,
                    fillColor: Colors.cyanAccent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
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