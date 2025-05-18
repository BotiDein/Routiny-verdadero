import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';
import 'simple_notification_service.dart';
import 'firebase_service.dart';

class SimpleNotificationManager {
  static final SimpleNotificationManager _instance = SimpleNotificationManager._internal();
  factory SimpleNotificationManager() => _instance;
  SimpleNotificationManager._internal();

  final SimpleNotificationService _notificationService = SimpleNotificationService();
  
  // Mostrar notificaciones para todas las tareas
  Future<void> showTaskNotifications(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isCompleted) {
        await _notificationService.showTaskNotification(task);
      }
    }
  }
  
  // Mostrar notificaciones para todos los hábitos
  Future<void> showHabitNotifications(List<Habit> habits) async {
    for (final habit in habits) {
      await _notificationService.showHabitNotification(habit);
    }
  }
  
  // Mostrar notificaciones para todos los hobbies
  Future<void> showHobbyNotifications(List<Hobby> hobbies) async {
    for (final hobby in hobbies) {
      await _notificationService.showHobbyNotification(hobby);
    }
  }
  
  // Mostrar notificación cuando se agrega una nueva tarea
  Future<void> onTaskAdded(Task task) async {
    await _notificationService.showTaskNotification(task);
  }
  
  // Mostrar notificación cuando se agrega un nuevo hábito
  Future<void> onHabitAdded(Habit habit) async {
    await _notificationService.showHabitNotification(habit);
  }
  
  // Mostrar notificación cuando se agrega un nuevo hobby
  Future<void> onHobbyAdded(Hobby hobby) async {
    await _notificationService.showHobbyNotification(hobby);
  }
  
  // Cancelar notificación cuando se elimina una tarea
  Future<void> onTaskDeleted(String taskId) async {
    await _notificationService.cancelNotification(taskId.hashCode);
  }
  
  // Cancelar notificación cuando se elimina un hábito
  Future<void> onHabitDeleted(String habitId) async {
    await _notificationService.cancelNotification(habitId.hashCode);
  }
  
  // Cancelar notificación cuando se elimina un hobby
  Future<void> onHobbyDeleted(String hobbyId) async {
    await _notificationService.cancelNotification(hobbyId.hashCode);
  }
  
  // Mostrar verificación diaria
  Future<void> showDailyCheck() async {
    await _notificationService.showDailyCheckNotification();
  }
  
  // Inicializar todas las notificaciones basadas en datos existentes
  Future<void> initializeAllNotifications() async {
    final firebaseService = FirebaseService();
    
    // Obtener datos
    final tasks = await firebaseService.getTasks().first;
    final habits = await firebaseService.getHabits().first;
    final hobbies = await firebaseService.getUserHobbies();
    
    // Mostrar notificaciones
    await showTaskNotifications(tasks);
    await showHabitNotifications(habits);
    await showHobbyNotifications(hobbies);
    
    // Mostrar verificación diaria
    await showDailyCheck();
  }
}
