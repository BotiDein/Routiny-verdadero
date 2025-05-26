import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';
import 'notification_service.dart';
import 'dart:async';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();
  
  final NotificationService _notificationService = NotificationService();
  
  // Claves para almacenar preferencias
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String taskNotificationsKey = 'task_notifications_enabled';
  static const String habitNotificationsKey = 'habit_notifications_enabled';
  static const String streakNotificationsKey = 'streak_notifications_enabled';
  static const String hobbyNotificationsKey = 'hobby_notifications_enabled';
  static const String permissionsRequestedKey = 'permissions_requested';
  
  bool _isInitialized = false;
  
  // Getter público para verificar inicialización
  bool get isInitialized => _isInitialized;
  
  Stream<NotificationResponse> get notificationStream => 
      _notificationService.notificationStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationManager already initialized');
      return;
    }
    
    try {
      print('Initializing NotificationManager...');
      
      // Inicializar el servicio de notificaciones
      await _notificationService.init();
      print('NotificationService initialized');
      
      // Verificar y solicitar permisos
      final permissionsGranted = await checkAndRequestPermissions();
      print('Permissions granted: $permissionsGranted');
      
      if (!permissionsGranted) {
        print('Notification permissions not granted');
        // No lanzar excepción, solo registrar
      }
      
      // Verificar si las notificaciones están habilitadas en el dispositivo
      final deviceNotificationsEnabled = 
          await _notificationService.areNotificationsEnabledOnDevice();
      print('Device notifications enabled: $deviceNotificationsEnabled');
      
      if (!deviceNotificationsEnabled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_notifications_disabled', true);
        print('Device notifications are disabled');
      }
      
      // Reprogramar notificaciones basadas en preferencias
      await _rescheduleAllNotificationsBasedOnPreferences();
      
      _isInitialized = true;
      print('NotificationManager initialized successfully');
    } catch (e) {
      print('Error initializing NotificationManager: $e');
      // No lanzar excepción para evitar que la app se cierre
      _isInitialized = false;
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsRequested = prefs.getBool(permissionsRequestedKey) ?? false;
      
      print('Permissions previously requested: $permissionsRequested');
      
      final granted = await _notificationService.requestPermissions();
      print('Permission request result: $granted');
      
      if (!permissionsRequested) {
        await prefs.setBool(permissionsRequestedKey, true);
      }
      
      return granted;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  Future<void> _rescheduleAllNotificationsBasedOnPreferences() async {
    try {
      print('Rescheduling notifications based on preferences...');
      
      if (await areHabitNotificationsEnabled()) {
        await _notificationService.scheduleHabitReminders();
        print('Habit reminders scheduled');
      }
      
      if (await areStreakNotificationsEnabled()) {
        await _notificationService.scheduleStreakReminder();
        print('Streak reminder scheduled');
      }
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(notificationsEnabledKey) ?? true;
    } catch (e) {
      print('Error checking if notifications are enabled: $e');
      return true;
    }
  }

  Future<bool> areTaskNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(taskNotificationsKey) ?? true;
    } catch (e) {
      print('Error checking task notifications: $e');
      return true;
    }
  }

  Future<bool> areHabitNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(habitNotificationsKey) ?? true;
    } catch (e) {
      print('Error checking habit notifications: $e');
      return true;
    }
  }

  Future<bool> areStreakNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(streakNotificationsKey) ?? true;
    } catch (e) {
      print('Error checking streak notifications: $e');
      return true;
    }
  }

  Future<bool> areHobbyNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(hobbyNotificationsKey) ?? true;
    } catch (e) {
      print('Error checking hobby notifications: $e');
      return true;
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) {
        print('NotificationManager not initialized, initializing now...');
        await initialize();
      }
      
      if (!await areTaskNotificationsEnabled()) {
        print('Task notifications are disabled');
        return;
      }
      
      await _notificationService.scheduleTaskNotification(task);
      print('Task notification scheduled for task: ${task.title}');
    } catch (e) {
      print('Error scheduling task notification: $e');
      // No relanzar la excepción para evitar crashes
    }
  }

  Future<void> scheduleTaskNotifications(List<Task> tasks) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areTaskNotificationsEnabled()) return;
      
      for (final task in tasks.where((t) => !t.isCompleted)) {
        await _notificationService.scheduleTaskNotification(task);
      }
      print('Multiple task notifications scheduled: ${tasks.length}');
    } catch (e) {
      print('Error scheduling multiple tasks: $e');
    }
  }

  Future<void> scheduleHobbyNotification(Hobby hobby, DateTime scheduledDate) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areHobbyNotificationsEnabled()) return;
      await _notificationService.scheduleHobbyNotification(hobby, scheduledDate);
      print('Hobby notification scheduled for: ${hobby.name}');
    } catch (e) {
      print('Error scheduling hobby notification: $e');
    }
  }

  Future<void> scheduleHabitReminders() async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areHabitNotificationsEnabled()) return;
      await _notificationService.scheduleHabitReminders();
      print('Habit reminders scheduled');
    } catch (e) {
      print('Error scheduling habit reminders: $e');
    }
  }

  Future<void> updateStreak() async {
    try {
      if (!_isInitialized) await initialize();
      await _notificationService.updateStreak();
      print('Streak updated');
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      if (!_isInitialized) await initialize();
      return await _notificationService.getCurrentStreak();
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(notificationsEnabledKey, enabled);
      
      if (enabled) {
        await _rescheduleAllNotificationsBasedOnPreferences();
      } else {
        await _notificationService.cancelAllNotifications();
      }
      print('Notifications enabled set to: $enabled');
    } catch (e) {
      print('Error setting notifications enabled: $e');
    }
  }

  Future<void> setTaskNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(taskNotificationsKey, enabled);
      print('Task notifications enabled set to: $enabled');
    } catch (e) {
      print('Error setting task notifications: $e');
    }
  }

  Future<void> setHabitNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(habitNotificationsKey, enabled);
      if (enabled) {
        await _notificationService.scheduleHabitReminders();
      }
      print('Habit notifications enabled set to: $enabled');
    } catch (e) {
      print('Error setting habit notifications: $e');
    }
  }

  Future<void> setStreakNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(streakNotificationsKey, enabled);
      if (enabled) {
        await _notificationService.scheduleStreakReminder();
      }
      print('Streak notifications enabled set to: $enabled');
    } catch (e) {
      print('Error setting streak notifications: $e');
    }
  }

  Future<void> setHobbyNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(hobbyNotificationsKey, enabled);
      print('Hobby notifications enabled set to: $enabled');
    } catch (e) {
      print('Error setting hobby notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        print('Initializing for test notification...');
        await initialize();
      }
      
      await _notificationService.showTestNotification();
      print('Test notification shown');
    } catch (e) {
      print('Error showing test notification: $e');
      rethrow; // Relanzar para que la UI pueda mostrar el error
    }
  }

  Future<void> dispose() async {
    try {
      await _notificationService.notificationStreamController.close();
    } catch (e) {
      print('Error disposing NotificationManager: $e');
    }
  }
}