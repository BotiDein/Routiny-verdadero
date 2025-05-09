import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/main_screen.dart';
import 'register_page.dart';

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
                  Icons.person,
                  size: screenWidth * 0.3,
                  color: Colors.blue,
                ),
                SizedBox(height: screenHeight * 0.04),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
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
                    onPressed: isLoading ? null : loginWithEmail,
                    child: Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    onPressed: isLoading ? null : loginWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: screenHeight * 0.03,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.g_mobiledata,
                              size: screenHeight * 0.03,
                            );
                          },
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'Iniciar sesión con Google',
                          style: TextStyle(fontSize: fontSize * 0.9),
                        ),
                      ],
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
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Text(
                    '¿No te has registrado aún?\nDa clic aquí',
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