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
  
  Stream<NotificationResponse> get notificationStream => 
      _notificationService.notificationStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _notificationService.init();
      final permissionsGranted = await checkAndRequestPermissions();
      if (!permissionsGranted) return;
      
      final deviceNotificationsEnabled = 
          await _notificationService.areNotificationsEnabledOnDevice();
      
      if (!deviceNotificationsEnabled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_notifications_disabled', true);
      }
      
      await _rescheduleAllNotificationsBasedOnPreferences();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing NotificationManager: $e');
      throw Exception('Failed to initialize NotificationManager: $e');
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsRequested = prefs.getBool(permissionsRequestedKey) ?? false;
      
      if (!permissionsRequested) {
        final granted = await _notificationService.requestPermissions();
        await prefs.setBool(permissionsRequestedKey, true);
        return granted;
      }
      return true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  Future<void> _rescheduleAllNotificationsBasedOnPreferences() async {
    if (await areHabitNotificationsEnabled()) {
      await _notificationService.scheduleHabitReminders();
    }
    
    if (await areStreakNotificationsEnabled()) {
      await _notificationService.scheduleStreakReminder();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsEnabledKey) ?? true;
  }

  Future<bool> areTaskNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(taskNotificationsKey) ?? true;
  }

  Future<bool> areHabitNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(habitNotificationsKey) ?? true;
  }

  Future<bool> areStreakNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(streakNotificationsKey) ?? true;
  }

  Future<bool> areHobbyNotificationsEnabled() async {
    if (!await areNotificationsEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hobbyNotificationsKey) ?? true;
  }

  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areTaskNotificationsEnabled()) return;
      await _notificationService.scheduleTaskNotification(task);
    } catch (e) {
      print('Error scheduling task notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleTaskNotifications(List<Task> tasks) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areTaskNotificationsEnabled()) return;
      
      for (final task in tasks.where((t) => !t.isCompleted)) {
        await _notificationService.scheduleTaskNotification(task);
      }
    } catch (e) {
      print('Error scheduling multiple tasks: $e');
      rethrow;
    }
  }

  Future<void> scheduleHobbyNotification(Hobby hobby, DateTime scheduledDate) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await areHobbyNotificationsEnabled()) return;
      await _notificationService.scheduleHobbyNotification(hobby, scheduledDate);
    } catch (e) {
      print('Error scheduling hobby notification: $e');
      rethrow;
    }
  }

  Future<void> updateStreak() async {
    try {
      if (!_isInitialized) await initialize();
      await _notificationService.updateStreak();
    } catch (e) {
      print('Error updating streak: $e');
      rethrow;
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
    } catch (e) {
      print('Error setting notifications enabled: $e');
      rethrow;
    }
  }

  Future<void> setTaskNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(taskNotificationsKey, enabled);
    await _rescheduleAllNotificationsBasedOnPreferences();
  }

  Future<void> setHabitNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(habitNotificationsKey, enabled);
    await _rescheduleAllNotificationsBasedOnPreferences();
  }

  Future<void> setStreakNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(streakNotificationsKey, enabled);
    await _rescheduleAllNotificationsBasedOnPreferences();
  }

  Future<void> setHobbyNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hobbyNotificationsKey, enabled);
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      print('Error cancelling all notifications: $e');
      rethrow;
    }
  }

  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) await initialize();
      await _notificationService.showTestNotification();
    } catch (e) {
      print('Error showing test notification: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _notificationService.notificationStreamController.close();
  }
}