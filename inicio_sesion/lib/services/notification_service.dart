import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/hobby.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:inicio_sesion/main.dart';

const String taskChannelId = 'task_channel';
const String habitChannelId = 'habit_channel';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Canales de notificación
  static const String taskChannelId = 'task_channel';
  static const String habitChannelId = 'habit_channel';
  static const String streakChannelId = 'streak_channel';
  static const String hobbyChannelId = 'hobby_channel';
  
  // IDs para notificaciones diarias de hábitos
  static const int morningHabitsId = 1001;
  static const int eveningHabitsId = 1002;
  static const int streakReminderId = 1003;
  
  // Horas para notificaciones diarias (24h format)
  static const int morningHour = 8; // 8:00 AM
  static const int eveningHour = 18; // 6:00 PM
  
  // Clave para almacenar la racha actual
  static const String currentStreakKey = 'current_streak';
  static const String lastCompletionDateKey = 'last_completion_date';
  
  // Flag para saber si ya se inicializó
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      print('NotificationService ya está inicializado');
      return;
      
    }

    try {
      // Inicializar timezone
      tz_init.initializeTimeZones();
      
      // Configuración para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS (si se necesita)
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          // Manejar notificaciones en iOS
        },
      );

      // Configuración general
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          navigatorKey.currentState?.pushNamed(
            '/notification-details',
            arguments: response.payload,
          );
        }
      },
    );
      // Inicializar plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Manejar la respuesta a la notificación si es necesario
          print('Notificación seleccionada: ${response.payload}');
        },
      );

      await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notificación seleccionada: ${response.payload}');
        },
      );

    // Crear los canales de notificación
    await _createNotificationChannels();
      
      // Marcar como inicializado
      _isInitialized = true;
      
      print('Inicialización de notificaciones completada');
    } catch (e) {
      print('Error al inicializar el servicio de notificaciones: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        taskChannelId,
        'Recordatorios de tareas',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        habitChannelId,
        'Recordatorios de hábitos',
        importance: Importance.high,
      ),
      // Puedes agregar más canales si los necesitas
    ];

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  // Programar notificación para una tarea (5 minutos antes)
  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      // Cancelar notificación existente para esta tarea (si existe)
      await cancelNotification(task.id.hashCode);
      
      // Si la tarea ya está completada, no programar notificación
      if (task.isCompleted) {
        return;
      }
      
      // Calcular tiempo de notificación (5 minutos antes)
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        task.date.subtract(const Duration(minutes: 5)),
        tz.local,
      );
      
      // Verificar si la fecha ya pasó
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      if (scheduledDate.isBefore(now)) {
        print('La fecha de notificación ya pasó: ${task.title}');
        return;
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        taskChannelId,
        'Recordatorios de tareas',
        channelDescription: 'Notificaciones para recordar tareas pendientes',
        importance: Importance.high,
        priority: Priority.high,
        color: Colors.blue,
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        'Tarea en 5 minutos',
        'Recuerda: ${task.title}',
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
      
      print('Notificación programada para: ${task.title} a las ${scheduledDate.toString()}');
    } catch (e) {
      print('Error al programar notificación para tarea: $e');
    }
  }

  // Programar notificación para un hobby
  Future<void> scheduleHobbyNotification(Hobby hobby, DateTime scheduledDate) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      // Cancelar notificación existente para este hobby (si existe)
      await cancelNotification(hobby.id.hashCode);
      
      // Verificar si la fecha ya pasó
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime notificationTime = tz.TZDateTime.from(
        scheduledDate.subtract(const Duration(minutes: 5)),
        tz.local,
      );
      
      if (notificationTime.isBefore(now)) {
        print('La fecha de notificación ya pasó: ${hobby.name}');
        return;
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        hobbyChannelId,
        'Recordatorios de hobbies',
        channelDescription: 'Notificaciones para recordar hobbies programados',
        importance: Importance.high,
        priority: Priority.high,
        color: Colors.purple,
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        hobby.id.hashCode,
        'Hobby programado',
        'En 5 minutos: ${hobby.name}',
        notificationTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hobby_${hobby.id}',
      );
      
      print('Notificación programada para hobby: ${hobby.name} a las ${notificationTime.toString()}');
    } catch (e) {
      print('Error al programar notificación para hobby: $e');
    }
  }

  // Programar notificaciones diarias para hábitos (mañana y tarde)
  Future<void> scheduleHabitReminders() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      // Cancelar notificaciones existentes
      await cancelNotification(morningHabitsId);
      await cancelNotification(eveningHabitsId);
      
      // Programar notificación matutina
      await _scheduleHabitReminder(
        morningHabitsId,
        'Buenos días',
        'Recuerda completar tus hábitos matutinos',
        morningHour,
        0,
      );
      
      // Programar notificación vespertina
      await _scheduleHabitReminder(
        eveningHabitsId,
        'Buenas tardes',
        'No olvides tus hábitos de la tarde',
        eveningHour,
        0,
      );
    } catch (e) {
      print('Error al programar recordatorios de hábitos: $e');
    }
  }
  
  // Método auxiliar para programar recordatorios de hábitos
  Future<void> _scheduleHabitReminder(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // Si la hora ya pasó hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        habitChannelId,
        'Recordatorios de hábitos',
        channelDescription: 'Notificaciones diarias para recordar hábitos',
        importance: Importance.high,
        priority: Priority.high,
        color: Colors.green,
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
          payload: 'habit_reminder',
        );
        
        print('Recordatorio de hábitos programado para las $hour:$minute');
      } catch (e) {
        // Si falla con DateTimeComponents.time, intentar sin él
        print('Error al programar con repetición diaria: $e');
        print('Intentando programar sin repetición diaria...');
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'habit_reminder',
        );
        
        print('Recordatorio de hábitos programado sin repetición para las $hour:$minute');
      }
    } catch (e) {
      print('Error al programar recordatorio de hábito: $e');
    }
  }
  
  // Programar notificación para recordar mantener la racha
  Future<void> scheduleStreakReminder() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      final currentStreak = await getCurrentStreak();
      if (currentStreak > 0) {
        // Cancelar notificación existente
        await cancelNotification(streakReminderId);
        
        // Programar para las 8 PM si la racha es > 0
        final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          20, // 8 PM
          0,
        );
        
        // Si la hora ya pasó hoy, programar para mañana
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          streakChannelId,
          'Recordatorios de racha',
          channelDescription: 'Notificaciones para mantener tu racha',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.orange,
        );
        
        const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iOSDetails,
        );

        final List<String> motivationalMessages = [
          '¡No pierdas tu racha de $currentStreak días!',
          '¡Mantén el ritmo! Llevas $currentStreak días consecutivos',
          '¡$currentStreak días de constancia! No te detengas ahora',
          'Tu racha de $currentStreak días está en juego. ¡Completa tus actividades!',
          '¡Sigue así! $currentStreak días de constancia y contando',
        ];
        
        // Seleccionar un mensaje aleatorio
        final random = Random();
        final message = motivationalMessages[random.nextInt(motivationalMessages.length)];

        await flutterLocalNotificationsPlugin.zonedSchedule(
          streakReminderId,
          '¡Mantén tu racha!',
          message,
          scheduledDate,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'streak_reminder',
        );
        
        print('Recordatorio de racha programado para las 20:00');
      }
    } catch (e) {
      print('Error al programar recordatorio de racha: $e');
    }
  }
  
  // Actualizar la racha cuando se completa una actividad
  Future<void> updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStreak = prefs.getInt(currentStreakKey) ?? 0;
      final lastCompletionStr = prefs.getString(lastCompletionDateKey);
      
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      
      // Si es la primera vez o si ya completó algo hoy
      if (lastCompletionStr == null || lastCompletionStr == todayStr) {
        await prefs.setInt(currentStreakKey, currentStreak + 1);
        await prefs.setString(lastCompletionDateKey, todayStr);
      } 
      // Si completó algo ayer, continuar la racha
      else {
        final lastCompletion = DateTime.parse(lastCompletionStr);
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (_formatDate(lastCompletion) == _formatDate(yesterday)) {
          await prefs.setInt(currentStreakKey, currentStreak + 1);
          await prefs.setString(lastCompletionDateKey, todayStr);
        } 
        // Si pasó más de un día, reiniciar la racha
        else {
          await prefs.setInt(currentStreakKey, 1);
          await prefs.setString(lastCompletionDateKey, todayStr);
        }
      }
      
      // Programar recordatorio de racha
      await scheduleStreakReminder();
    } catch (e) {
      print('Error al actualizar racha: $e');
    }
  }
  
  // Obtener la racha actual
  Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(currentStreakKey) ?? 0;
    } catch (e) {
      print('Error al obtener racha actual: $e');
      return 0;
    }
  }
  
  // Formatear fecha como string (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('Error al cancelar notificación: $e');
    }
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('Error al cancelar todas las notificaciones: $e');
    }
  }
  
  // Mostrar una notificación inmediata (para pruebas)
  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Notificaciones de prueba',
        channelDescription: 'Canal para probar notificaciones',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );
      
      await flutterLocalNotificationsPlugin.show(
        0,
        'Prueba de notificación',
        'Esta es una notificación de prueba',
        notificationDetails,
      );
      
      print('Notificación de prueba mostrada');
    } catch (e) {
      print('Error al mostrar notificación de prueba: $e');
    }
  }
  
  // Verificar si las notificaciones están habilitadas en el dispositivo
  Future<bool> areNotificationsEnabledOnDevice() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          try {
            // Intentar usar el método más reciente
            return await androidPlugin.areNotificationsEnabled() ?? false;
          } catch (e) {
            print('Error al verificar permisos de notificación: $e');
            return true; // Asumir que están habilitadas si no podemos verificar
          }
        }
      } else if (Platform.isIOS) {
        // En iOS, no hay un método directo para verificar
        // Podríamos implementar esto en el futuro
      }
      
      // Por defecto, asumir que están habilitadas
      return true;
    } catch (e) {
      print('Error al verificar si las notificaciones están habilitadas: $e');
      return true; // Asumir que están habilitadas por defecto
    }
  }
}
