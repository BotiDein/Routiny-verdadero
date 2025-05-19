import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/landing_page.dart';
import 'notification_settings_screen.dart';
import '../services/notification_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double screenWidth;
  late double screenHeight;
  late ScaffoldMessengerState _messenger;
  final NotificationManager _notificationManager = NotificationManager();
  int _currentStreak = 0;
  bool _isLoadingStreak = true;

  double scaleWidth(double value) => value * screenWidth / 720;
  double scaleHeight(double value) => value * screenHeight / 1280;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    setState(() {
      _isLoadingStreak = true;
    });
    
    final streak = await _notificationManager.getCurrentStreak();
    
    setState(() {
      _currentStreak = streak;
      _isLoadingStreak = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
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
            // Sección de racha
            if (!_isLoadingStreak && _currentStreak > 0) _buildStreakSection(),
            
            if (!_isLoadingStreak && _currentStreak > 0) SizedBox(height: scaleHeight(20)),
            
            _buildConfigItem(
              Icons.notifications,
              'Notificaciones',
              optionFontSize,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            SizedBox(height: scaleHeight(20)),
            _buildConfigItem(
              Icons.person,
              'Mi cuenta',
              optionFontSize,
              () => _showAccountDialog(context),
            ),
            SizedBox(height: scaleHeight(20)),
            _buildConfigItem(
              Icons.chat_bubble_outline,
              'Sugerencias',
              optionFontSize,
              () => _showSuggestionDialog(context),
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

  Widget _buildStreakSection() {
    return Container(
      padding: EdgeInsets.all(scaleWidth(20)),
      margin: EdgeInsets.only(bottom: scaleHeight(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFE0FFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: scaleWidth(50),
          ),
          SizedBox(width: scaleWidth(15)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu racha actual',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              Text(
                '$_currentStreak días consecutivos',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0047AB),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ],
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

  void _confirmLogout(BuildContext context) async {
    _showMessageDialog(
      context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que quieres seguir?',
      onConfirm: () async {
        Navigator.of(context).pop();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LandingPage()),
            (_) => false,
          );
        }
      },
    );
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
              'ROUTINY es una app móvil para organizar tu rutina y mejorar tu bienestar personal, académico y emocional. '
              'Diseñada para estudiantes, freelancers y cualquier persona que quiera gestionar mejor su tiempo.\n\n'
              'Incluye herramientas para seguir hábitos saludables, organizar tareas académicas, registrar hobbies y ver resúmenes de tu progreso. '
              'Todo esto en una interfaz sencilla, sin funciones comerciales, y con protección de tus datos.',
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
              onPressed: () async {
                final suggestion = suggestionController.text.trim();
                if (suggestion.isNotEmpty) {
                  Navigator.of(context).pop();
                  
                  final user = FirebaseAuth.instance.currentUser;
                  final uid = user?.uid ?? 'anónimo';
                  final email = user?.email ?? 'anónimo';
                  
                  // Guardar la sugerencia en Firestore
                  await FirebaseFirestore.instance.collection('sugerencias').add({
                    'texto': suggestion,
                    'uid': uid,
                    'email': email,
                    'fecha': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    _messenger.showSnackBar(
                      const SnackBar(content: Text('¡Gracias por tu sugerencia!')),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showAccountDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final name = userData?['name'] ?? 'Desconocido';
    final email = user.email ?? 'Sin correo';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.all(0),
          contentPadding: const EdgeInsets.all(24),
          backgroundColor: const Color(0xFFE0FFFF),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mi cuenta',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi nombre', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(name),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Mi correo electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email),
              const Divider(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BBB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      if (mounted) {
                        _messenger.showSnackBar(
                          const SnackBar(content: Text('Se ha enviado un correo para restablecer tu contraseña')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        _messenger.showSnackBar(
                          SnackBar(content: Text('Error al enviar el correo: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Cambiar contraseña'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
