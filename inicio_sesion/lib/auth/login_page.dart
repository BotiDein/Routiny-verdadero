import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/main_screen.dart';
import 'register_page.dart';
import '../auth/landing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginWithEmail() async {
    if (!mounted) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Por favor, completa todos los campos.';
      });
      return;
    }

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        error = 'El formato del correo no es válido.';
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensajeError;
      switch (e.code) {
        case 'user-not-found':
          mensajeError = 'No se encontró una cuenta con ese correo.';
          break;
        case 'wrong-password':
          mensajeError = 'La contraseña es incorrecta.';
          break;
        case 'invalid-email':
          mensajeError = 'El correo electrónico es inválido.';
          break;
        case 'too-many-requests':
          mensajeError = 'Demasiados intentos. Inténtalo más tarde.';
          break;
        default:
          mensajeError = e.message ?? 'Ocurrió un error al iniciar sesión.';
      }

      setState(() => error = mensajeError);
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

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) return;

      final usersRef = FirebaseFirestore.instance.collection('users');

      await usersRef.doc(user.uid).set({
        'uid': user.uid,
        'nombre': user.displayName ?? '',
        'correo': user.email ?? '',
        'fotoURL': user.photoURL ?? '',
        'fechaRegistro': FieldValue.serverTimestamp(),
        'proveedor': 'google',
      }, SetOptions(merge: true));

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

  void mostrarDialogoRecuperacion() {
    final TextEditingController correoRecuperacion = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: correoRecuperacion,
            decoration: const InputDecoration(hintText: 'Ingresa tu correo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final email = correoRecuperacion.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, escribe tu correo'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Se ha enviado un correo para restablecer tu contraseña.',
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al enviar correo: $e')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    double scale(double base) => base * (width / 375);

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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: scale(30)),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                width: scale(150),
                height: scale(150),
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    size: scale(150),
                    color: Colors.grey,
                  );
                },
              ),
              SizedBox(height: scale(20)),
              Text(
                'Routiny',
                style: TextStyle(
                  fontFamily: 'RobotoBold',
                  fontSize: scale(40),
                  color: const Color(0xFF0052A9),
                ),
              ),
              SizedBox(height: scale(30)),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontSize: scale(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: scale(8)),
              TextField(
                controller: emailController,
                style: TextStyle(fontSize: scale(16)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 202, 255, 251),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scale(10)),
                  ),
                  contentPadding: EdgeInsets.all(scale(12)),
                ),
              ),
              SizedBox(height: scale(20)),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: scale(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: scale(8)),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                style: TextStyle(fontSize: scale(16)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 202, 255, 251),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(scale(10)),
                  ),
                  contentPadding: EdgeInsets.all(scale(12)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: mostrarDialogoRecuperacion,
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: scale(14),
                      color: Colors.blue[800],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(20)),
              SizedBox(
                width: double.infinity,
                height: scale(45),
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scale(8)),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: scale(16)),
                  ),
                ),
              ),
              SizedBox(height: scale(15)),

              SizedBox(
                width: double.infinity,
                height: scale(45),
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scale(8)),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google_logo.png',
                        height: scale(22),
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata),
                      ),
                      SizedBox(width: scale(10)),
                      Text(
                        'Iniciar sesión con Google',
                        style: TextStyle(fontSize: scale(15)),
                      ),
                    ],
                  ),
                ),
              ),

              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: scale(20)),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red, fontSize: scale(14)),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: scale(25)),
              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                child: Text(
                  '¿No tienes una cuenta?',
                  style: TextStyle(
                    fontSize: scale(15),
                    color: const Color(0xFF0052A9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
