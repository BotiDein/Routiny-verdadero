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
  
  
  // Clave para almacenar preferencias de notificaciones
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String taskNotificationsKey = 'task_notifications_enabled';
  static const String habitNotificationsKey = 'habit_notifications_enabled';
  static const String streakNotificationsKey = 'streak_notifications_enabled';
  static const String hobbyNotificationsKey = 'hobby_notifications_enabled';
  
  // Flag para saber si ya se inicializó
  bool _isInitialized = false;
  
  // Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationManager ya está inicializado');
      return;
    }

    try {
      // Inicializar el servicio de notificaciones
      await _notificationService.init();
      
      // Verificar si las notificaciones están habilitadas en el dispositivo
      final bool deviceNotificationsEnabled = 
          await _notificationService.areNotificationsEnabledOnDevice();
      
      if (!deviceNotificationsEnabled) {
        print('Las notificaciones están deshabilitadas en el dispositivo');
        // Guardar esta información para mostrar un mensaje al usuario
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_notifications_disabled', true);
      }
      
      // Programar notificaciones diarias si están habilitadas
      final bool habitNotificationsEnabled = await areHabitNotificationsEnabled();
      if (habitNotificationsEnabled) {
        await _notificationService.scheduleHabitReminders();
      }
      
      // Programar recordatorio de racha si está habilitado
      final bool streakNotificationsEnabled = await areStreakNotificationsEnabled();
      if (streakNotificationsEnabled) {
        await _notificationService.scheduleStreakReminder();
      }
      
      // Marcar como inicializado
      _isInitialized = true;
      
      print('NotificationManager inicializado correctamente');
    } catch (e) {
      print('Error al inicializar NotificationManager: $e');
    }
  }
  
  // Programar notificación para una tarea
  Future<void> scheduleTaskNotification(Task task) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final bool taskNotificationsEnabled = await areTaskNotificationsEnabled();
      if (taskNotificationsEnabled) {
        await _notificationService.scheduleTaskNotification(task);
      }
    } catch (e) {
      print('Error al programar notificación de tarea: $e');
    }
  }
  
  // Programar notificación para un hobby
  Future<void> scheduleHobbyNotification(Hobby hobby, DateTime scheduledDate) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final bool hobbyNotificationsEnabled = await areHobbyNotificationsEnabled();
      if (hobbyNotificationsEnabled) {
        await _notificationService.scheduleHobbyNotification(hobby, scheduledDate);
      }
    } catch (e) {
      print('Error al programar notificación de hobby: $e');
    }
  }
  
  // Programar notificaciones para múltiples tareas
  Future<void> scheduleTaskNotifications(List<Task> tasks) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final bool taskNotificationsEnabled = await areTaskNotificationsEnabled();
      if (taskNotificationsEnabled) {
        for (final task in tasks) {
          if (!task.isCompleted) {
            await _notificationService.scheduleTaskNotification(task);
          }
        }
      }
    } catch (e) {
      print('Error al programar múltiples notificaciones de tareas: $e');
    }
  }
  
  // Actualizar la racha cuando se completa una actividad
  Future<void> updateStreak() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await _notificationService.updateStreak();
    } catch (e) {
      print('Error al actualizar racha: $e');
    }
  }
  
  // Obtener la racha actual
  Future<int> getCurrentStreak() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      return await _notificationService.getCurrentStreak();
    } catch (e) {
      print('Error al obtener racha actual: $e');
      return 0;
    }
  }
  
  // Verificar si las notificaciones están habilitadas en general
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(notificationsEnabledKey) ?? true; // Habilitado por defecto
    } catch (e) {
      print('Error al verificar si las notificaciones están habilitadas: $e');
      return true; // Asumir habilitadas por defecto en caso de error
    }
  }
  
  // Verificar si las notificaciones de tareas están habilitadas
  Future<bool> areTaskNotificationsEnabled() async {
    try {
      final bool notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(taskNotificationsKey) ?? true; // Habilitado por defecto
    } catch (e) {
      print('Error al verificar si las notificaciones de tareas están habilitadas: $e');
      return true; // Asumir habilitadas por defecto en caso de error
    }
  }
  
  // Verificar si las notificaciones de hábitos están habilitadas
  Future<bool> areHabitNotificationsEnabled() async {
    try {
      final bool notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(habitNotificationsKey) ?? true; // Habilitado por defecto
    } catch (e) {
      print('Error al verificar si las notificaciones de hábitos están habilitadas: $e');
      return true; // Asumir habilitadas por defecto en caso de error
    }
  }
  
  // Verificar si las notificaciones de racha están habilitadas
  Future<bool> areStreakNotificationsEnabled() async {
    try {
      final bool notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(streakNotificationsKey) ?? true; // Habilitado por defecto
    } catch (e) {
      print('Error al verificar si las notificaciones de racha están habilitadas: $e');
      return true; // Asumir habilitadas por defecto en caso de error
    }
  }
  
  // Verificar si las notificaciones de hobbies están habilitadas
  Future<bool> areHobbyNotificationsEnabled() async {
    try {
      final bool notificationsEnabled = await areNotificationsEnabled();
      if (!notificationsEnabled) return false;
      
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(hobbyNotificationsKey) ?? true; // Habilitado por defecto
    } catch (e) {
      print('Error al verificar si las notificaciones de hobbies están habilitadas: $e');
      return true; // Asumir habilitadas por defecto en caso de error
    }
  }
  
  // Habilitar/deshabilitar notificaciones en general
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(notificationsEnabledKey, enabled);
      
      if (!enabled) {
        // Cancelar todas las notificaciones si se deshabilitan
        await _notificationService.cancelAllNotifications();
      } else {
        // Reprogramar notificaciones si se habilitan
        final bool habitNotificationsEnabled = await areHabitNotificationsEnabled();
        if (habitNotificationsEnabled) {
          await _notificationService.scheduleHabitReminders();
        }
        
        final bool streakNotificationsEnabled = await areStreakNotificationsEnabled();
        if (streakNotificationsEnabled) {
          await _notificationService.scheduleStreakReminder();
        }
      }
    } catch (e) {
      print('Error al establecer estado de notificaciones: $e');
    }
  }
  
  // Habilitar/deshabilitar notificaciones de tareas
  Future<void> setTaskNotificationsEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(taskNotificationsKey, enabled);
      
      if (!enabled) {
        // Cancelar notificaciones de tareas existentes
        // (No podemos cancelar solo las de tareas, así que reprogramamos las otras)
        await _notificationService.cancelAllNotifications();
        
        // Reprogramar otras notificaciones
        final bool habitNotificationsEnabled = await areHabitNotificationsEnabled();
        if (habitNotificationsEnabled) {
          await _notificationService.scheduleHabitReminders();
        }
        
        final bool streakNotificationsEnabled = await areStreakNotificationsEnabled();
        if (streakNotificationsEnabled) {
          await _notificationService.scheduleStreakReminder();
        }
      }
    } catch (e) {
      print('Error al establecer estado de notificaciones de tareas: $e');
    }
  }
  
  // Habilitar/deshabilitar notificaciones de hábitos
  Future<void> setHabitNotificationsEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(habitNotificationsKey, enabled);
      
      if (enabled) {
        // Programar notificaciones de hábitos
        await _notificationService.scheduleHabitReminders();
      } else {
        // Cancelar notificaciones de hábitos
        await _notificationService.cancelNotification(NotificationService.morningHabitsId);
        await _notificationService.cancelNotification(NotificationService.eveningHabitsId);
      }
    } catch (e) {
      print('Error al establecer estado de notificaciones de hábitos: $e');
    }
  }
  
  // Habilitar/deshabilitar notificaciones de racha
  Future<void> setStreakNotificationsEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(streakNotificationsKey, enabled);
      
      if (enabled) {
        // Programar notificación de racha
        await _notificationService.scheduleStreakReminder();
      } else {
        // Cancelar notificación de racha
        await _notificationService.cancelNotification(NotificationService.streakReminderId);
      }
    } catch (e) {
      print('Error al establecer estado de notificaciones de racha: $e');
    }
  }
  
  // Habilitar/deshabilitar notificaciones de hobbies
  Future<void> setHobbyNotificationsEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(hobbyNotificationsKey, enabled);
    } catch (e) {
      print('Error al establecer estado de notificaciones de hobbies: $e');
    }
  }
  
  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      print('Error al cancelar todas las notificaciones: $e');
    }
  }

  // Programar notificaciones diarias para hábitos
  Future<void> scheduleHabitReminders() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final bool habitNotificationsEnabled = await areHabitNotificationsEnabled();
      if (habitNotificationsEnabled) {
        await _notificationService.scheduleHabitReminders();
      }
    } catch (e) {
      print('Error al programar recordatorios de hábitos: $e');
    }
  }

  // Programar recordatorio de racha
  Future<void> scheduleStreakReminder() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await _notificationService.scheduleStreakReminder();
    } catch (e) {
      print('Error al programar recordatorio de racha: $e');
    }
  }
  
  // Mostrar una notificación de prueba
  Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await _notificationService.showTestNotification();
    } catch (e) {
      print('Error al mostrar notificación de prueba: $e');
    }
  }
}
