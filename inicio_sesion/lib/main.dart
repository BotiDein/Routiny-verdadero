import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_manager.dart';
import 'package:timezone/data/latest_all.dart' as tz;

//GlobalKey para navegación
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuración inicial
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await initializeDateFormatting('es_ES', null);
  
  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: "AIzaSyCPwX9upDp-flkmNsCavMonifBQluastBQ",
              authDomain: "proyecto-final-6b20e.firebaseapp.com",
              projectId: "proyecto-final-6b20e",
              storageBucket: "proyecto-final-6b20e.firebasestorage.app",
              messagingSenderId: "826917239714",
              appId: "1:826917239714:web:34136d38b90440492ed0fb",
            )
          : DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }
  
  // Inicializar timezone para notificaciones (solo en móvil)
  if (!kIsWeb) {
    try {
      tz.initializeTimeZones();
      print('Timezone inicializado correctamente');
    } catch (e) {
      print('Error al inicializar timezone: $e');
    }
  }
  
  // Inicializar notificaciones (solo en móvil)
  if (!kIsWeb) {
    try {
      // Inicializar el gestor de notificaciones
      final notificationManager = NotificationManager();
      await notificationManager.initialize();
      print('Sistema de notificaciones inicializado correctamente');
      
      // Configurar el listener para notificaciones
      _setupNotificationListener(notificationManager);
      
    } catch (e) {
      print('Error al inicializar el sistema de notificaciones: $e');
      // No detener la app, solo registrar el error
    }
  }
  
  runApp(const MyApp());
}

void _setupNotificationListener(NotificationManager notificationManager) {
  try {
    // Escuchar notificaciones
    notificationManager.notificationStream.listen(
      (response) {
        print('Notificación recibida: ${response.payload}');
        _handleNotificationResponse(response);
      },
      onError: (error) {
        print('Error en el stream de notificaciones: $error');
      },
    );
  } catch (e) {
    print('Error configurando listener de notificaciones: $e');
  }
}

void _handleNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  
  if (payload == null) return;
  
  try {
    // Manejar diferentes tipos de notificaciones
    if (payload.startsWith('task_')) {
      _handleTaskNotification(payload);
    } else if (payload.startsWith('hobby_')) {
      _handleHobbyNotification(payload);
    } else if (payload == 'habit_reminder') {
      _handleHabitNotification();
    } else if (payload == 'streak_reminder') {
      _handleStreakNotification();
    } else if (payload == 'test_notification') {
      _handleTestNotification();
    }
  } catch (e) {
    print('Error manejando respuesta de notificación: $e');
  }
}

void _handleTaskNotification(String payload) {
  print('Manejando notificación de tarea: $payload');
  _showNotificationSnackBar('Tienes una tarea pendiente', Colors.blue);
}

void _handleHobbyNotification(String payload) {
  print('Manejando notificación de hobby: $payload');
  _showNotificationSnackBar('Es hora de tu hobby', Colors.purple);
}

void _handleHabitNotification() {
  print('Manejando notificación de hábitos');
  _showNotificationSnackBar('Recuerda completar tus hábitos', Colors.green);
}

void _handleStreakNotification() {
  print('Manejando notificación de racha');
  _showStreakDialog();
}

void _handleTestNotification() {
  print('Notificación de prueba recibida correctamente');
  _showNotificationSnackBar('¡Notificación de prueba recibida!', Colors.orange);
}

void _showNotificationSnackBar(String message, Color color) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

void _showStreakDialog() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange),
              SizedBox(width: 8),
              Text('¡Mantén tu racha!'),
            ],
          ),
          content: const Text('No olvides completar tus actividades de hoy para mantener tu racha.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí podrías navegar a la pantalla principal
              },
              child: const Text('Ver actividades'),
            ),
          ],
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Routiny',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFFE0FFFF),
        useMaterial3: true,
        // Configuración compatible para SnackBar
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          // Removido el parámetro 'margin' que causaba el error
        ),
      ),
      home: const SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
    );
  }
}