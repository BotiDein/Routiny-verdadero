import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../models/hobby.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final StreamController<NotificationResponse> notificationStreamController = 
      StreamController<NotificationResponse>.broadcast();

  // Canales de notificación
  static const String taskChannelId = 'task_channel';
  static const String habitChannelId = 'habit_channel';
  static const String streakChannelId = 'streak_channel';
  static const String hobbyChannelId = 'hobby_channel';
  static const String testChannelId = 'test_channel';
  
  // IDs para notificaciones
  static const int morningHabitsId = 1001;
  static const int eveningHabitsId = 1002;
  static const int streakReminderId = 1003;
  
  // Horarios
  static const int morningHour = 8;
  static const int eveningHour = 18;
  
  // Claves para racha
  static const String currentStreakKey = 'current_streak';
  static const String lastCompletionDateKey = 'last_completion_date';
  
  bool _isInitialized = false;
  
  // Getter público para verificar inicialización
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Inicializar timezone
      tz_init.initializeTimeZones();
      
      // Configuración para Android - CRÍTICO: especificar icono explícitamente
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializar el plugin
      final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification received: ${response.payload}');
          notificationStreamController.add(response);
        },
        onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
          print('Background notification received: ${response.payload}');
          notificationStreamController.add(response);
        },
      );
      
      if (initialized != true) {
        throw Exception('Failed to initialize notifications');
      }
      
      await _setupNotificationChannels();
      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
      throw Exception('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Canal para tareas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            taskChannelId,
            'Recordatorios de tareas',
            importance: Importance.high,
            description: 'Notificaciones para recordar tareas pendientes',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para hábitos
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            habitChannelId,
            'Recordatorios de hábitos',
            importance: Importance.high,
            description: 'Notificaciones diarias para recordar hábitos',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para rachas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            streakChannelId,
            'Recordatorios de racha',
            importance: Importance.high,
            description: 'Notificaciones para mantener tu racha',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para hobbies
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            hobbyChannelId,
            'Recordatorios de hobbies',
            importance: Importance.high,
            description: 'Notificaciones para recordar hobbies programados',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para pruebas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            testChannelId,
            'Notificaciones de prueba',
            importance: Importance.max,
            description: 'Canal para probar notificaciones',
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Solicitar permisos de notificación exacta (Android 12+)
          final bool? exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
          print('Exact alarm permission: $exactAlarmPermission');
          
          // Verificar si las notificaciones están habilitadas
          final bool? enabled = await androidPlugin.areNotificationsEnabled();
          print('Notifications enabled: $enabled');
          
          return enabled ?? false;
        }
        return true;
      } else if (Platform.isIOS) {
        final bool? result = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }
      return false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<bool> areNotificationsEnabledOnDevice() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          return await androidPlugin.areNotificationsEnabled() ?? false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking device notification status: $e');
      return true;
    }
  }

  // Método ROBUSTO para crear detalles de notificación Android
  AndroidNotificationDetails _createRobustAndroidDetails(
    String channelId,
    String channelName,
    String description,
  ) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: description,
      importance: Importance.high,
      priority: Priority.high,
      // CRÍTICO: Especificar explícitamente el icono
      icon: '@mipmap/ic_launcher',
      // CRÍTICO: No usar propiedades que puedan ser nulas
      largeIcon: null,
      styleInformation: null,
      // Configuración básica y segura
      autoCancel: true,
      ongoing: false,
      silent: false,
      enableVibration: true,
      playSound: true,
    );
  }

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) await init();
      
      await cancelNotification(task.id.hashCode);
      
      if (task.isCompleted) {
        print('Task is completed, not scheduling notification');
        return;
      }

      final notificationTime = task.date.subtract(const Duration(minutes: 5));
      final now = DateTime.now();
      
      if (notificationTime.isBefore(now)) {
        print('Notification time is in the past, not scheduling');
        return;
      }
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      final AndroidNotificationDetails androidDetails = _createRobustAndroidDetails(
        taskChannelId,
        'Recordatorios de tareas',
        'Notificaciones para recordar tareas pendientes',
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails, 
        iOS: iOSDetails
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        'Tarea en 5 minutos',
        'Recuerda: ${task.title}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
      
      print('Task notification scheduled for: $scheduledDate');
    } catch (e) {
      print('Error scheduling task notification: $e');
      throw Exception('Failed to schedule task notification: $e');
    }
  }

  Future<void> scheduleHobbyNotification(Hobby hobby, DateTime scheduledDate) async {
    try {
      if (!_isInitialized) await init();
      
      await cancelNotification(hobby.id.hashCode);
      
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime notificationTime = tz.TZDateTime.from(
        scheduledDate.subtract(const Duration(minutes: 5)),
        tz.local,
      );
      
      if (notificationTime.isBefore(now)) {
        print('Hobby notification time is in the past, not scheduling');
        return;
      }
      
      final AndroidNotificationDetails androidDetails = _createRobustAndroidDetails(
        hobbyChannelId,
        'Recordatorios de hobbies',
        'Notificaciones para recordar hobbies programados',
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        hobby.id.hashCode,
        'Hobby programado',
        'En 5 minutos: ${hobby.name}',
        notificationTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hobby_${hobby.id}',
      );
      
      print('Hobby notification scheduled for: $notificationTime');
    } catch (e) {
      print('Error scheduling hobby notification: $e');
      throw Exception('Failed to schedule hobby notification: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) await init();
      
      final AndroidNotificationDetails androidDetails = _createRobustAndroidDetails(
        testChannelId,
        'Notificaciones de prueba',
        'Canal para probar notificaciones',
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );
      
      await flutterLocalNotificationsPlugin.show(
        0,
        'Prueba de notificación',
        'Esta es una notificación de prueba - ${DateTime.now().toString()}',
        notificationDetails,
        payload: 'test_notification',
      );
      
      print('Test notification shown');
    } catch (e) {
      print('Error showing test notification: $e');
      throw Exception('Failed to show test notification: $e');
    }
  }

  Future<void> scheduleHabitReminders() async {
    try {
      if (!_isInitialized) await init();
      
      await cancelNotification(morningHabitsId);
      await cancelNotification(eveningHabitsId);
      
      await _scheduleHabitReminder(
        morningHabitsId,
        'Buenos días',
        'Recuerda completar tus hábitos matutinos',
        morningHour,
        0,
      );
      
      await _scheduleHabitReminder(
        eveningHabitsId,
        'Buenas tardes',
        'No olvides tus hábitos de la tarde',
        eveningHour,
        0,
      );
      
      print('Habit reminders scheduled');
    } catch (e) {
      print('Error scheduling habit reminders: $e');
      throw Exception('Failed to schedule habit reminders: $e');
    }
  }

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
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      final AndroidNotificationDetails androidDetails = _createRobustAndroidDetails(
        habitChannelId,
        'Recordatorios de hábitos',
        'Notificaciones diarias para recordar hábitos',
      );
      
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_reminder',
      );
    } catch (e) {
      print('Error scheduling habit reminder: $e');
      throw Exception('Failed to schedule habit reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  Future<void> updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStreak = prefs.getInt(currentStreakKey) ?? 0;
      final lastCompletionStr = prefs.getString(lastCompletionDateKey);
      
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      
      if (lastCompletionStr == null || lastCompletionStr == todayStr) {
        await prefs.setInt(currentStreakKey, currentStreak + 1);
        await prefs.setString(lastCompletionDateKey, todayStr);
      } else {
        final lastCompletion = DateTime.parse(lastCompletionStr);
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (_formatDate(lastCompletion) == _formatDate(yesterday)) {
          await prefs.setInt(currentStreakKey, currentStreak + 1);
          await prefs.setString(lastCompletionDateKey, todayStr);
        } else {
          await prefs.setInt(currentStreakKey, 1);
          await prefs.setString(lastCompletionDateKey, todayStr);
        }
      }
      
      await scheduleStreakReminder();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(currentStreakKey) ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  Future<void> scheduleStreakReminder() async {
    try {
      if (!_isInitialized) await init();
      
      final currentStreak = await getCurrentStreak();
      if (currentStreak > 0) {
        await cancelNotification(streakReminderId);
        
        final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          20, // 8 PM
          0,
        );
        
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        
        final AndroidNotificationDetails androidDetails = _createRobustAndroidDetails(
          streakChannelId,
          'Recordatorios de racha',
          'Notificaciones para mantener tu racha',
        );
        
        const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final NotificationDetails notificationDetails = NotificationDetails(
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
        
        final random = Random();
        final message = motivationalMessages[random.nextInt(motivationalMessages.length)];

        await flutterLocalNotificationsPlugin.zonedSchedule(
          streakReminderId,
          '¡Mantén tu racha!',
          message,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'streak_reminder',
        );
      }
    } catch (e) {
      print('Error scheduling streak reminder: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}