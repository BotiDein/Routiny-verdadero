import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_manager.dart';
import 'services/notification_service.dart';
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
  
  // Inicializar timezone para notificaciones
  tz.initializeTimeZones();
  
  // Inicializar notificaciones
  final notificationService = NotificationService();
  await notificationService.init();
  
  // Escuchar notificaciones en primer plano
  notificationService.notificationStreamController.stream.listen((response) {
    print('Notificación recibida: ${response.payload}');
    // Aquí puedes manejar la notificación cuando la app está en primer plano
    // Por ejemplo, mostrar un diálogo o navegar a una pantalla específica
  });
  
  // Inicializar el gestor de notificaciones
  try {
    final notificationManager = NotificationManager();
    await notificationManager.initialize();
    print('Sistema de notificaciones inicializado correctamente');
  } catch (e) {
    print('Error al inicializar el sistema de notificaciones: $e');
  }
  
  runApp(const MyApp());
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
