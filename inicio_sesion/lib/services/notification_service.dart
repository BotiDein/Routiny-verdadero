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
import '../models/habit.dart';

// CRÍTICO: Función top-level para manejar notificaciones en segundo plano
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification tapped: ${notificationResponse.payload}');
}

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
  static const String hobbyChannelId = 'hobby_channel';
  static const String streakChannelId = 'streak_channel';
  static const String testChannelId = 'test_channel';

  // IDs base para diferentes tipos de notificaciones
  static const int taskNotificationBase = 1000;
  static const int habitNotificationBase = 2000;
  static const int hobbyNotificationBase = 3000;
  static const int streakNotificationBase = 4000;
  static const int testNotificationId = 9999;

  // Horarios para recordatorios automáticos
  static const int morningHour = 8;
  static const int eveningHour = 20;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Stream<NotificationResponse> get notificationStream =>
      notificationStreamController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone
      tz_init.initializeTimeZones();

      // Configuración para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // Inicializar con backgroundHandler
      final bool? initialized = await flutterLocalNotificationsPlugin
          .initialize(
            initializationSettings,
            onDidReceiveNotificationResponse: (NotificationResponse response) {
              print('Foreground notification received: ${response.payload}');
              notificationStreamController.add(response);
            },
            onDidReceiveBackgroundNotificationResponse:
                notificationTapBackground,
          );

      if (initialized != true) {
        throw Exception('Failed to initialize notifications plugin');
      }

      await _setupNotificationChannels();
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      throw Exception('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        // Canal para tareas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            taskChannelId,
            'Recordatorios de Tareas',
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
            'Recordatorios de Hábitos',
            importance: Importance.high,
            description: 'Notificaciones para recordar hábitos diarios',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para hobbies
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            hobbyChannelId,
            'Recordatorios de Hobbies',
            importance: Importance.high,
            description: 'Notificaciones para recordar tiempo de hobbies',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para rachas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            streakChannelId,
            'Recordatorios de Racha',
            importance: Importance.high,
            description: 'Notificaciones para mantener tu racha diaria',
            playSound: true,
            enableVibration: true,
          ),
        );

        // Canal para pruebas
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            testChannelId,
            'Notificaciones de Prueba',
            importance: Importance.max,
            description: 'Canal para probar notificaciones',
            playSound: true,
            enableVibration: true,
          ),
        );

        print('✅ Notification channels created successfully');
      }
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          // Solicitar permisos de notificación
          final bool? notificationPermission =
              await androidPlugin.requestNotificationsPermission();
          print('Notification permission granted: $notificationPermission');

          // Solicitar permisos de alarma exacta (Android 12+)
          final bool? exactAlarmPermission =
              await androidPlugin.requestExactAlarmsPermission();
          print('Exact alarm permission granted: $exactAlarmPermission');

          // Verificar estado final
          final bool? enabled = await androidPlugin.areNotificationsEnabled();
          print('Final notifications enabled status: $enabled');

          return enabled ?? false;
        }
        return true;
      } else if (Platform.isIOS) {
        final bool? result = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
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
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          final bool? enabled = await androidPlugin.areNotificationsEnabled();
          print('Device notifications enabled: $enabled');
          return enabled ?? false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking device notification status: $e');
      return true;
    }
  }

  // ==================== NOTIFICACIONES DE TAREAS ====================

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) await init();

      // No programar si la tarea ya está completada
      if (task.isCompleted) {
        print('Task ${task.id} is completed, skipping notification');
        return;
      }

      // Cancelar notificación existente
      await cancelTaskNotification(task.id);

      // Programar notificación 5 minutos antes
      final notificationTime = task.date.subtract(const Duration(minutes: 5));
      final now = DateTime.now();

      if (notificationTime.isBefore(now)) {
        print('Task notification time is in the past, skipping');
        return;
      }

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        notificationTime,
        tz.local,
      );

      // Determinar icono según prioridad
      String priorityText =
          task.priority == 3
              ? '🔴 ALTA'
              : task.priority == 2
              ? '🟡 MEDIA'
              : '🟢 BAJA';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            taskChannelId,
            'Recordatorios de Tareas',
            channelDescription:
                'Notificaciones para recordar tareas pendientes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
            enableVibration: true,
            playSound: true,
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

      final notificationId =
          taskNotificationBase + task.id.hashCode.abs() % 1000;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '📋 Tarea en 5 minutos - $priorityText',
        '${task.title}\n${task.description.isNotEmpty ? task.description : 'Categoría: ${task.category}'}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );

      print('✅ Task notification scheduled for: $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling task notification: $e');
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    try {
      final notificationId =
          taskNotificationBase + taskId.hashCode.abs() % 1000;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print('Task notification cancelled for: $taskId');
    } catch (e) {
      print('Error cancelling task notification: $e');
    }
  }

  // ==================== NOTIFICACIONES DE HÁBITOS ====================

  Future<void> scheduleHabitReminders(List<Habit> habits) async {
    try {
      if (!_isInitialized) await init();

      // Cancelar recordatorios existentes
      await cancelAllHabitNotifications();

      final now = DateTime.now();
      final today = now.weekday % 7; // 0 = domingo, 1 = lunes, etc.

      // Filtrar hábitos que deben ejecutarse hoy y no están completados
      final todayHabits =
          habits.where((habit) {
            final isActiveToday =
                habit.days.length > today && habit.days[today] != 0;
            final isNotCompleted = habit.days[today] != 2; // 2 = completado
            return isActiveToday && isNotCompleted;
          }).toList();

      if (todayHabits.isEmpty) {
        print('No habits to schedule for today');
        return;
      }

      // Programar recordatorio matutino
      await _scheduleHabitReminder(
        habitNotificationBase + 1,
        '🌅 Buenos días - Hábitos matutinos',
        'Tienes ${todayHabits.length} hábito${todayHabits.length > 1 ? 's' : ''} pendiente${todayHabits.length > 1 ? 's' : ''} para hoy',
        morningHour,
        0,
        'habit_morning',
      );

      // Programar recordatorio vespertino
      await _scheduleHabitReminder(
        habitNotificationBase + 2,
        '🌙 Recordatorio vespertino',
        'No olvides completar tus hábitos antes de que termine el día',
        eveningHour,
        0,
        'habit_evening',
      );

      print('✅ Habit reminders scheduled for ${todayHabits.length} habits');
    } catch (e) {
      print('❌ Error scheduling habit reminders: $e');
    }
  }

  Future<void> _scheduleHabitReminder(
    int id,
    String title,
    String body,
    int hour,
    int minute,
    String payload,
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

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            habitChannelId,
            'Recordatorios de Hábitos',
            channelDescription: 'Notificaciones para recordar hábitos diarios',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
            enableVibration: true,
            playSound: true,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      print('Habit reminder scheduled for: $scheduledDate');
    } catch (e) {
      print('Error scheduling habit reminder: $e');
    }
  }

  Future<void> cancelAllHabitNotifications() async {
    try {
      // Cancelar recordatorios matutinos y vespertinos
      await flutterLocalNotificationsPlugin.cancel(habitNotificationBase + 1);
      await flutterLocalNotificationsPlugin.cancel(habitNotificationBase + 2);
      print('All habit notifications cancelled');
    } catch (e) {
      print('Error cancelling habit notifications: $e');
    }
  }

  // ==================== NOTIFICACIONES DE HOBBIES ====================

  Future<void> scheduleHobbyNotification(
    Hobby hobby,
    DateTime scheduledTime,
  ) async {
    try {
      if (!_isInitialized) await init();

      // Cancelar notificación existente
      await cancelHobbyNotification(hobby.id);

      // Programar notificación 10 minutos antes
      final notificationTime = scheduledTime.subtract(
        const Duration(minutes: 10),
      );
      final now = DateTime.now();

      if (notificationTime.isBefore(now)) {
        print('Hobby notification time is in the past, skipping');
        return;
      }

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        notificationTime,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            hobbyChannelId,
            'Recordatorios de Hobbies',
            channelDescription:
                'Notificaciones para recordar tiempo de hobbies',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
            enableVibration: true,
            playSound: true,
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

      final notificationId =
          hobbyNotificationBase + hobby.id.hashCode.abs() % 1000;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '🎨 Tiempo de hobby en 10 minutos',
        '${hobby.icon} ${hobby.name}\nMeta semanal: ${hobby.weeklyGoal}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'hobby_${hobby.id}',
      );

      print('✅ Hobby notification scheduled for: $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling hobby notification: $e');
    }
  }

  Future<void> cancelHobbyNotification(String hobbyId) async {
    try {
      final notificationId =
          hobbyNotificationBase + hobbyId.hashCode.abs() % 1000;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print('Hobby notification cancelled for: $hobbyId');
    } catch (e) {
      print('Error cancelling hobby notification: $e');
    }
  }

  // ==================== NOTIFICACIONES DE RACHA ====================

  Future<void> scheduleStreakReminder() async {
    try {
      if (!_isInitialized) await init();

      final currentStreak = await getCurrentStreak();

      if (currentStreak == 0) {
        print('No streak to maintain, skipping reminder');
        return;
      }

      // Cancelar recordatorio existente
      await flutterLocalNotificationsPlugin.cancel(streakNotificationBase);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21, // 9 PM
        0,
      );

      // Si la hora ya pasó hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            streakChannelId,
            'Recordatorios de Racha',
            channelDescription: 'Notificaciones para mantener tu racha diaria',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
            enableVibration: true,
            playSound: true,
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
        '¡No pierdas tu racha de $currentStreak días! 🔥',
        '¡Mantén el ritmo! Llevas $currentStreak días consecutivos 💪',
        '¡$currentStreak días de constancia! No te detengas ahora 🚀',
        'Tu racha de $currentStreak días está en juego. ¡Completa tus actividades! ⭐',
        '¡Sigue así! $currentStreak días de constancia y contando 🎯',
      ];

      final random = Random();
      final message =
          motivationalMessages[random.nextInt(motivationalMessages.length)];

      await flutterLocalNotificationsPlugin.zonedSchedule(
        streakNotificationBase,
        '🔥 ¡Mantén tu racha!',
        message,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'streak_reminder',
      );

      print('✅ Streak reminder scheduled for: $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling streak reminder: $e');
    }
  }

  // ==================== GESTIÓN DE RACHA ====================

  Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('current_streak') ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  Future<void> updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStreak = prefs.getInt('current_streak') ?? 0;
      final lastUpdateStr = prefs.getString('last_streak_update');

      final today = DateTime.now();
      final todayStr = _formatDate(today);

      // Si ya se actualizó hoy, no hacer nada
      if (lastUpdateStr == todayStr) {
        print('Streak already updated today');
        return;
      }

      // Si es el primer día o el día siguiente al último update
      if (lastUpdateStr == null) {
        // Primera vez
        await prefs.setInt('current_streak', 1);
        await prefs.setString('last_streak_update', todayStr);
        print('✅ Streak started: 1 day');
      } else {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final yesterday = today.subtract(const Duration(days: 1));

        if (_formatDate(lastUpdate) == _formatDate(yesterday)) {
          // Día consecutivo
          final newStreak = currentStreak + 1;
          await prefs.setInt('current_streak', newStreak);
          await prefs.setString('last_streak_update', todayStr);
          print('✅ Streak updated: $newStreak days');
        } else {
          // Se rompió la racha
          await prefs.setInt('current_streak', 1);
          await prefs.setString('last_streak_update', todayStr);
          print('🔄 Streak reset: 1 day');
        }
      }

      // Programar recordatorio para mantener la racha
      await scheduleStreakReminder();
    } catch (e) {
      print('❌ Error updating streak: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==================== UTILIDADES ====================

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) await init();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            testChannelId,
            'Notificaciones de Prueba',
            channelDescription: 'Canal para probar notificaciones',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
            enableVibration: true,
            playSound: true,
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

      final now = DateTime.now();
      final timeString = '${now.hour}:${now.minute}:${now.second}';

      await flutterLocalNotificationsPlugin.show(
        testNotificationId,
        '🔔 Prueba de Notificación - Routiny',
        'Notificación enviada a las $timeString - ¡Sistema funcionando correctamente!',
        notificationDetails,
        payload: 'test_notification',
      );

      print('✅ Test notification sent successfully at $timeString');
    } catch (e) {
      print('❌ Error showing test notification: $e');
      throw Exception('Failed to show test notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error canceling all notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}
