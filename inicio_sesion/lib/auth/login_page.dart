import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/main_screen.dart';
import 'register_page.dart';
import '../auth/landing_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Iniciar sesión con email y contraseña
  Future<void> loginWithEmail() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
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

  // Iniciar sesión con Google
  Future<void> loginWithGoogle() async {
    if (!mounted) return;

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => error = 'Error con Google Sign-In: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.6;
    final buttonHeight = screenHeight * 0.05;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.012,
    );

    final titleFontSize = screenWidth * 0.10;
    final labelFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.045;
    final errorFontSize = screenWidth * 0.038;
    final linkFontSize = screenWidth * 0.042;

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
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo y título
                SizedBox(height: screenHeight * 0.05), // Espacio superior
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 170,  // Tamaño fijo 
                      height: 170,  // Tamaño fijo 
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          size: 217,  // Tamaño de la imagen en caso de error
                          color: Colors.grey,
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Routiny',
                      style: TextStyle(
                        fontFamily: 'RobotoBold',
                        fontSize: titleFontSize,
                        color: const Color(0xFF0052A9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                // Campo de texto para el correo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Usuario',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: emailController,
                  style: TextStyle(fontSize: labelFontSize),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                // Campo de texto para la contraseña
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(fontSize: labelFontSize),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 202, 255, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    contentPadding: inputPadding,
                  ),
                ),
                SizedBox(height: screenHeight * 0.06),

                // Botón de inicio de sesión
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
                    onPressed: isLoading ? null : loginWithEmail,
                    child: Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: buttonFontSize),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Botón de Google
// Botón de Google con texto y la imagen al lado izquierdo
SizedBox(
  width: buttonWidth*1.25,  height: buttonHeight,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      side: BorderSide(color: Colors.grey, width: 1), // Borde gris opcional
    ),
    onPressed: isLoading ? null : loginWithGoogle,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/google_logo.png',
          height: screenHeight * 0.04,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.g_mobiledata,
              size: screenHeight * 0.04,
            );
          },
        ),
        SizedBox(width: screenWidth * 0.02), // Espacio entre el icono y el texto
        Text(
          'Iniciar sesión con Google',
          style: TextStyle(
            fontSize: buttonFontSize,
            color: Colors.black,
          ),
        ),
      ],
    ),
  ),
),


                // Mostrar errores
                if (error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.02),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: errorFontSize,
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.025),

                // Enlace para crear cuenta
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Text(
                    '¿No tienes una cuenta?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: linkFontSize,
                      color: const Color(0xFF0052A9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
