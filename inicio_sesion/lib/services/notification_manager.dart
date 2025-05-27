import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import '../models/task.dart';
import '../models/hobby.dart';
import '../models/habit.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();

  // Stream para escuchar notificaciones
  Stream<NotificationResponse> get notificationStream =>
      _notificationService.notificationStream;

  /// Inicializar el sistema de notificaciones
  Future<void> initialize() async {
    try {
      await _notificationService.init();
      await _notificationService.requestPermissions();
      print('✅ NotificationManager initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationManager: $e');
      rethrow;
    }
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabledOnDevice();
  }

  // ==================== GESTIÓN DE TAREAS ====================

  /// Programar notificación para una tarea
  Future<void> scheduleTaskNotification(Task task) async {
    await _notificationService.scheduleTaskNotification(task);
  }

  /// Cancelar notificación de una tarea
  Future<void> cancelTaskNotification(String taskId) async {
    await _notificationService.cancelTaskNotification(taskId);
  }

  /// Actualizar notificaciones cuando una tarea cambia
  Future<void> updateTaskNotification(Task task) async {
    if (task.isCompleted) {
      await cancelTaskNotification(task.id);
    } else {
      await scheduleTaskNotification(task);
    }
  }

  // ==================== GESTIÓN DE HÁBITOS ====================

  /// Programar recordatorios diarios de hábitos
  Future<void> scheduleHabitReminders(List<Habit> habits) async {
    await _notificationService.scheduleHabitReminders(habits);
  }

  /// Cancelar todos los recordatorios de hábitos
  Future<void> cancelAllHabitNotifications() async {
    await _notificationService.cancelAllHabitNotifications();
  }

  // ==================== GESTIÓN DE HOBBIES ====================

  /// Programar notificación para un hobby
  Future<void> scheduleHobbyNotification(
    Hobby hobby,
    DateTime scheduledTime,
  ) async {
    await _notificationService.scheduleHobbyNotification(hobby, scheduledTime);
  }

  /// Cancelar notificación de un hobby
  Future<void> cancelHobbyNotification(String hobbyId) async {
    await _notificationService.cancelHobbyNotification(hobbyId);
  }

  // ==================== GESTIÓN DE RACHA ====================

  /// Actualizar la racha diaria
  Future<void> updateStreak() async {
    await _notificationService.updateStreak();
  }

  /// Obtener la racha actual
  Future<int> getCurrentStreak() async {
    return await _notificationService.getCurrentStreak();
  }

  /// Programar recordatorio de racha
  Future<void> scheduleStreakReminder() async {
    await _notificationService.scheduleStreakReminder();
  }

  // ==================== UTILIDADES ====================

  /// Mostrar notificación de prueba
  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification();
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  /// Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }

  /// Programar todas las notificaciones necesarias
  Future<void> scheduleAllNotifications({
    List<Task>? tasks,
    List<Habit>? habits,
    List<Hobby>? hobbies,
  }) async {
    try {
      // Programar notificaciones de tareas
      if (tasks != null) {
        for (final task in tasks) {
          if (!task.isCompleted) {
            await scheduleTaskNotification(task);
          }
        }
      }

      // Programar recordatorios de hábitos
      if (habits != null && habits.isNotEmpty) {
        await scheduleHabitReminders(habits);
      }

      // Programar recordatorio de racha
      await scheduleStreakReminder();

      print('✅ All notifications scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling all notifications: $e');
    }
  }
}
