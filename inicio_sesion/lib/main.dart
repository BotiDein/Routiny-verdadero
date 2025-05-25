import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_manager.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializamos timezone para notificaciones programadas
  tz.initializeTimeZones();
  
  // Configuramos la aplicación para que solo se pueda usar en modo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializamos los datos de localización para español
  await initializeDateFormatting('es_ES', null);
  
  try {
    // Inicializamos Firebase
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
    // Continuar de todos modos, ya que la app puede funcionar sin Firebase
  }
  
  // Inicializar el gestor de notificaciones avanzado
  try {
    final notificationManager = NotificationManager();
    await notificationManager.initialize();
    print('Sistema de notificaciones inicializado correctamente');
  } catch (e) {
    print('Error al inicializar el sistema de notificaciones: $e');
    // Continuar de todos modos, ya que la app puede funcionar sin notificaciones
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Routiny',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFFE0FFFF),
        useMaterial3: true,
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
