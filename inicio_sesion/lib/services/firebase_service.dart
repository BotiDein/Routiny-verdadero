import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';
import 'notification_manager.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String userId;
  final NotificationManager _notificationManager = NotificationManager();

  // Constructor que acepta un userId opcional
  FirebaseService([String? uid])
    : userId = uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // Colección de tareas del usuario
  CollectionReference get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');
      
  // Colección de hábitos del usuario
  CollectionReference get _habitsCollection =>
      _firestore.collection('users').doc(userId).collection('habits');

  // Obtener todas las tareas
  Stream<List<Task>> getTasks() {
    return _tasksCollection.orderBy('date', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Obtener tareas por fecha
  Stream<List<Task>> getTasksByDate(DateTime date) {
    // Crear rango para el día completo
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _tasksCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }
  
  // Obtener tareas para un rango de fechas (para el resumen mensual)
  Future<List<Task>> getTasksForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _tasksCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();
          
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error al obtener tareas para rango de fechas: $e');
      return [];
    }
  }

  // Añadir una tarea
  Future<void> addTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toMap());
    
    // Programar notificación para la nueva tarea
    await _notificationManager.scheduleTaskNotification(task);
  }

  // Actualizar una tarea
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
    
    // Programar o cancelar notificación según el estado
    if (task.isCompleted) {
      // Cancelar notificación si la tarea está completada
      await _notificationManager.cancelAllNotifications();
      
      // Actualizar racha
      await _notificationManager.updateStreak();
    } else {
      // Programar notificación si la tarea no está completada
      await _notificationManager.scheduleTaskNotification(task);
    }
  }

  // Eliminar una tarea
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
    
    // Cancelar notificación para esta tarea
    await _notificationManager.cancelAllNotifications();
  }

  // Marcar tarea como completada
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _tasksCollection.doc(taskId).update({'isCompleted': isCompleted});
    
    // Si se marca como completada, actualizar racha
    if (isCompleted) {
      await _notificationManager.updateStreak();
    }
  }

  // Obtener fechas con tareas para un mes específico
  Future<List<DateTime>> getDatesWithTasks(int year, int month) async {
    // Primer día del mes
    final firstDay = DateTime(year, month, 1);
    // Último día del mes (incluyendo el último día)
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    print('Buscando tareas desde: ${firstDay.toString()} hasta: ${lastDay.toString()}');

    final snapshot =
        await _tasksCollection
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
            .get();

    print('Número de tareas encontradas: ${snapshot.docs.length}');

    // Extraer fechas únicas
    final Set<String> uniqueDates = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateString = '${date.year}-${date.month}-${date.day}';
      uniqueDates.add(dateString);
      print('Tarea para fecha: $dateString');
    }

    // Convertir a lista de DateTime
    final result = uniqueDates.map((dateStr) {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList();
    
    print('Fechas únicas con tareas: ${result.length}');
    for (var date in result) {
      print('Fecha con tarea: ${date.toString()}');
    }
    
    return result;
  }
  
  // MÉTODOS PARA HÁBITOS - ACTUALIZADOS PARA USAR EL MODELO HABIT
  
  // Obtener todos los hábitos como Stream
Stream<List<Habit>> getHabits() {
  try {
    return _habitsCollection
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Habit.fromMap(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('Error al convertir documento a Habit: $e');
              return _getDefaultHabit(doc.id); // Puedes eliminar también si prefieres
            }
          }).toList();
        });
  } catch (e) {
    print('Error en getHabits(): $e');
    return Stream.value([]); //Retorna una lista vacía en caso de error
  }
}

// Obtener todos los hábitos como Future
Future<List<Habit>> getHabitsFuture() async {
  try {
    final snapshot = await _habitsCollection.get();
    
    return snapshot.docs.map((doc) {
      try {
        return Habit.fromMap(doc.data() as Map<String, dynamic>);
      } catch (e) {
        print('Error al convertir documento a Habit: $e');
        return _getDefaultHabit(doc.id); // Puedes quitar este también si no quieres ningún fallback
      }
    }).toList();
  } catch (e) {
    print('Error al obtener hábitos: $e');
    return []; // Retorna lista vacía si hay error
  }
}

  
  // Añadir un nuevo hábito
  Future<void> addHabit(Habit habit) async {
    try {
      await _habitsCollection.doc(habit.id).set(habit.toMap());
      
      // Programar notificaciones de hábitos si es necesario
      await _notificationManager.scheduleHabitReminders();
    } catch (e) {
      print('Error al añadir hábito: $e');
      throw Exception('No se pudo añadir el hábito: $e');
    }
  }
  
  // Actualizar un hábito existente
  Future<void> updateHabit(Habit habit) async {
    try {
      await _habitsCollection.doc(habit.id).update(habit.toMap());
      
      // Verificar si se completó un hábito hoy
      final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
      if (habit.days[today] == 2) {
        // Si se marcó como completado, actualizar racha
        await _notificationManager.updateStreak();
      }
    } catch (e) {
      print('Error al actualizar hábito: $e');
      throw Exception('No se pudo actualizar el hábito: $e');
    }
  }
  
  // Eliminar un hábito
  Future<void> deleteHabit(String habitId) async {
    try {
      await _habitsCollection.doc(habitId).delete();
    } catch (e) {
      print('Error al eliminar hábito: $e');
      throw Exception('No se pudo eliminar el hábito: $e');
    }
  }
  
  // Actualizar el estado de un hábito para el día actual
  Future<void> updateHabitStatus(String habitId, int status) async {
    try {
      // Obtener el hábito actual
      final doc = await _habitsCollection.doc(habitId).get();
      
      if (!doc.exists) {
        throw Exception('El hábito no existe');
      }
      
      final habit = Habit.fromMap(doc.data() as Map<String, dynamic>);
      
      // Actualizar el estado para el día actual
      final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
      final updatedDays = List<int>.from(habit.days);
      updatedDays[today] = status;
      
      // Actualizar en Firestore
      await _habitsCollection.doc(habitId).update({'days': updatedDays});
      
      // Si se marca como completado, actualizar racha
      if (status == 2) {
        await _notificationManager.updateStreak();
      }
    } catch (e) {
      print('Error al actualizar estado del hábito: $e');
      throw Exception('No se pudo actualizar el estado del hábito: $e');
    }
  }
  
  // Hábito por defecto en caso de error
  Habit _getDefaultHabit(String id) {
    return Habit(
      id: id,
      name: 'Hábito (error)',
      category: 'General',
      type: 'count',
      description: 'Hubo un error al cargar este hábito',
      days: [0, 0, 0, 0, 0, 0, 0],
      createdAt: DateTime.now(),
    );
  }
  
  // MÉTODOS PARA HOBBIES
  
  // MÉTODO PARA GUARDAR LOS HOBBIES DEL USUARIO EN FIREBASE
  Future<void> saveUserHobbies(List<Hobby> hobbies) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final hobbiesRef = _firestore.collection('users').doc(user.uid).collection('hobbies');

    for (final hobby in hobbies) {
      await hobbiesRef.doc(hobby.id).set(hobby.toMap());
      
      // Programar notificaciones para hobbies si tienen fechas programadas
      if (hobby.registeredTimes.isNotEmpty) {
        for (final timeEntry in hobby.registeredTimes) {
          if (timeEntry is Map && timeEntry.containsKey('date')) {
            final date = DateTime.parse(timeEntry['date']);
            if (date.isAfter(DateTime.now())) {
              await _notificationManager.scheduleHobbyNotification(hobby, date);
            }
          }
        }
      }
    }
  }

  Future<void> saveSingleUserHobby(Hobby hobby) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('hobbies')
        .doc(hobby.id);

    await docRef.set(hobby.toMap());
    
    // Programar notificaciones para este hobby si tiene fechas programadas
    if (hobby.registeredTimes.isNotEmpty) {
      for (final timeEntry in hobby.registeredTimes) {
        if (timeEntry is Map && timeEntry.containsKey('date')) {
          final date = DateTime.parse(timeEntry['date']);
          if (date.isAfter(DateTime.now())) {
            await _notificationManager.scheduleHobbyNotification(hobby, date);
          }
        }
      }
    }
  }

  // MÉTODO PARA OBTENER LOS HOBBIES DEL USUARIO DESDE FIREBASE
  Future<List<Hobby>> getUserHobbies() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final snapshot = await _firestore.collection('users').doc(user.uid).collection('hobbies').get();

    return snapshot.docs.map((doc) => Hobby.fromMap(doc.data())).toList();
  }

  // MÉTODO PARA ELIMINAR UN HOBBY DEL USUARIO EN FIREBASE
  Future<void> deleteUserHobby(String hobbyId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('hobbies')
        .doc(hobbyId);

    await docRef.delete();
    
    // Cancelar notificaciones para este hobby
    await _notificationManager.cancelAllNotifications();
  }
}

FirebaseFirestore db = FirebaseFirestore.instance;
