import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';

class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración general (solo Android)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Inicializar plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar la respuesta a la notificación si es necesario
        print('Notificación seleccionada: ${response.payload}');
      },
    );
  }

  // Mostrar notificación inmediata para una tarea
  Future<void> showTaskNotification(Task task) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Recordatorios de tareas',
      channelDescription: 'Notificaciones para recordar tareas pendientes',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      task.id.hashCode,
      'Tarea pendiente',
      'No olvides completar: ${task.title}',
      notificationDetails,
      payload: 'task_${task.id}',
    );
  }

  // Mostrar notificación inmediata para un hábito
  Future<void> showHabitNotification(Habit habit) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Recordatorios de hábitos',
      channelDescription: 'Notificaciones para recordar hábitos pendientes',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.green,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      habit.id.hashCode,
      'Hábito pendiente',
      'No olvides completar tu hábito: ${habit.name}',
      notificationDetails,
      payload: 'habit_${habit.id}',
    );
  }

  // Mostrar notificación inmediata para un hobby
  Future<void> showHobbyNotification(Hobby hobby) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hobby_channel',
      'Recordatorios de hobbies',
      channelDescription: 'Notificaciones para recordar hobbies programados',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.purple,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      hobby.id.hashCode,
      'Hobby programado',
      'Hoy es día de disfrutar tu hobby: ${hobby.name}',
      notificationDetails,
      payload: 'hobby_${hobby.id}',
    );
  }

  // Mostrar notificación diaria
  Future<void> showDailyCheckNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_check_channel',
      'Verificación diaria',
      channelDescription: 'Notificación diaria para revisar actividades',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Revisa tu día',
      'Verifica tus tareas, hábitos y hobbies para hoy',
      notificationDetails,
      payload: 'daily_check',
    );
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
