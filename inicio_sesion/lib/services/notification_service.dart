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

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      tz_init.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          notificationStreamController.add(
            NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              id: id,
              payload: payload,
            )
          );
        },
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          notificationStreamController.add(response);
        },
        onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
          notificationStreamController.add(response);
        },
      );
      
      await _setupNotificationChannels();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
        taskChannelId,
        'Recordatorios de tareas',
        importance: Importance.high,
        description: 'Notificaciones para recordar tareas pendientes',
        playSound: true,
      );

      const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
        habitChannelId,
        'Recordatorios de hábitos',
        importance: Importance.high,
        description: 'Notificaciones diarias para recordar hábitos',
        playSound: true,
      );

      const AndroidNotificationChannel streakChannel = AndroidNotificationChannel(
        streakChannelId,
        'Recordatorios de racha',
        importance: Importance.high,
        description: 'Notificaciones para mantener tu racha',
        playSound: true,
      );

      const AndroidNotificationChannel hobbyChannel = AndroidNotificationChannel(
        hobbyChannelId,
        'Recordatorios de hobbies',
        importance: Importance.high,
        description: 'Notificaciones para recordar hobbies programados',
        playSound: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(taskChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(habitChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(streakChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(hobbyChannel);
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        return true; // Android maneja los permisos automáticamente desde Android 13
      } else if (Platform.isIOS) {
        return true; // iOS maneja los permisos durante la inicialización
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
          try {
            return await androidPlugin.areNotificationsEnabled() ?? false;
          } catch (e) {
            print('Error checking notification permissions: $e');
            return true;
          }
        }
      }
      return true;
    } catch (e) {
      print('Error checking device notification status: $e');
      return true;
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
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) await init();
      
      await cancelNotification(task.id.hashCode);
      
      if (task.isCompleted) return;

      final notificationTime = task.date.subtract(const Duration(minutes: 5));
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
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

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        'Tarea en 5 minutos',
        'Recuerda: ${task.title}',
        scheduledDate,
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
    } catch (e) {
      print('Error scheduling task notification: $e');
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
    } catch (e) {
      print('Error scheduling habit reminders: $e');
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

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_reminder',
      );
    } catch (e) {
      print('Error scheduling habit reminder: $e');
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
      }
    } catch (e) {
      print('Error scheduling streak reminder: $e');
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
    } catch (e) {
      print('Error scheduling hobby notification: $e');
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

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) await init();
      
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
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}