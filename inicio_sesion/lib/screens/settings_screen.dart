import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    double scaleWidth(double value) => value * screenWidth / 720;
    double scaleHeight(double value) => value * screenHeight / 1280;

    final titleFontSize = screenWidth * 0.06;
    final optionFontSize = screenWidth * 0.045;
    final iconSize = screenWidth * 0.06;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scaleWidth(30),
          vertical: scaleHeight(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigItem(Icons.person, 'Mi cuenta', optionFontSize, () {}),
            SizedBox(height: scaleHeight(20)),
            _buildConfigItem(
              Icons.chat_bubble_outline,
              'Sugerencias',
              optionFontSize,
              () => _handleSuggestion(context),
            ),
            SizedBox(height: scaleHeight(20)),
            _buildConfigItem(
              Icons.info_outline,
              'Acerca de la app',
              optionFontSize,
              () => _showAboutDialog(context),
            ),
            SizedBox(height: scaleHeight(20)),
            _buildConfigItem(
              Icons.logout,
              'Cerrar sesión',
              optionFontSize,
              () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(IconData icon, String text, double fontSize, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: fontSize * 1.5, color: Colors.black),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSuggestion(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessageDialog(
        context,
        title: 'Cuenta requerida',
        message:
            'Debe ingresar con una cuenta si desea mandarnos una sugerencia, ¿desea ir al inicio de sesión?',
        onConfirm: () {
          Navigator.of(context).pop();
          // Navegar a la pantalla de inicio de sesión directamente
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false, // Esto elimina las pantallas anteriores
          );
        },
      );
    } else {
      _showSuggestionDialog(context);
    }
  }

  void _confirmLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessageDialog(
        context,
        title: 'Sin cuenta activa',
        message: 'Aún no has ingresado una cuenta, ¿quieres salir de la aplicación?',
        onConfirm: () => Navigator.of(context).pop(),
      );
    } else {
      _showMessageDialog(
        context,
        title: 'Cerrar sesión',
        message: '¿Estás seguro de que quieres seguir?',
        onConfirm: () async {
          Navigator.of(context).pop(); // Cierra el diálogo primero

          await FirebaseAuth.instance.signOut(); // Luego espera

          // Espera un breve momento para garantizar que el contexto esté listo
          Future.delayed(const Duration(milliseconds: 100), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesión cerrada')),
            );
          });
        },
      );
    }
  }

  void _showMessageDialog(BuildContext context,
      {required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontFamily: 'Roboto')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('No')),
            ElevatedButton(onPressed: onConfirm, child: const Text('Sí')),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Acerca de la app',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showSuggestionDialog(BuildContext context) {
    final TextEditingController suggestionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Sugerencias',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡Tu opinión nos importa!',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: suggestionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu opinión aquí...',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                final suggestion = suggestionController.text.trim();
                if (suggestion.isNotEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Gracias por tu sugerencia!')),
                  );
                  // Aquí podrías guardar en Firestore si lo deseas.
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}