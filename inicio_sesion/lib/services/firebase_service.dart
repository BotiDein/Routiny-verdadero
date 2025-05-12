import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  // Constructor que acepta un userId opcional
  FirebaseService([String? uid])
    : userId = uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // Colección de tareas del usuario
  CollectionReference get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');
      
  // Colección de hábitos del usuario
  CollectionReference get _habitsCollection =>
      _firestore.collection('users').doc(userId).collection('habits');
      
  // Colección de hobbies del usuario
  CollectionReference get _hobbiesCollection =>
      _firestore.collection('users').doc(userId).collection('hobbies');

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
    final snapshot = await _tasksCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();
        
    return snapshot.docs.map((doc) {
      return Task.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Añadir una tarea
  Future<void> addTask(Task task) {
    return _tasksCollection.doc(task.id).set(task.toMap());
  }

  // Actualizar una tarea
  Future<void> updateTask(Task task) {
    return _tasksCollection.doc(task.id).update(task.toMap());
  }

  // Eliminar una tarea
  Future<void> deleteTask(String taskId) {
    return _tasksCollection.doc(taskId).delete();
  }

  // Marcar tarea como completada
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) {
    return _tasksCollection.doc(taskId).update({'isCompleted': isCompleted});
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
      print('Tarea para fecha: ${dateString}');
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
  
  // MÉTODOS PARA HÁBITOS
  
  // Obtener todos los hábitos
  Future<List<Habit>> getHabits() async {
    final snapshot = await _habitsCollection.get();
    return snapshot.docs.map((doc) {
      return Habit.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // Obtener hábitos para un rango de fechas
  Future<List<Habit>> getHabitsForDateRange(DateTime startDate, DateTime endDate) async {
    final snapshot = await _habitsCollection
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
        
    return snapshot.docs.map((doc) {
      return Habit.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // MÉTODOS PARA HOBBIES
  
  // Obtener todos los hobbies
  Future<List<Hobby>> getHobbies() async {
    final snapshot = await _hobbiesCollection.get();
    return snapshot.docs.map((doc) {
      return Hobby.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // Obtener hobbies para un rango de fechas
  Future<List<Hobby>> getHobbiesForDateRange(DateTime startDate, DateTime endDate) async {
    final snapshot = await _hobbiesCollection
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
        
    return snapshot.docs.map((doc) {
      return Hobby.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // MÉTODOS PARA EL RESUMEN
  
  // Obtener datos para el resumen mensual
  Future<Map<String, dynamic>> getMonthlyData(int year, int month) async {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    
    // Obtener datos de tareas, hábitos y hobbies
    final tasks = await getTasksForDateRange(firstDayOfMonth, lastDayOfMonth);
    final habits = await getHabitsForDateRange(firstDayOfMonth, lastDayOfMonth);
    final hobbies = await getHobbiesForDateRange(firstDayOfMonth, lastDayOfMonth);
    
    // Calcular estadísticas
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    
    // Calcular rachas de hábitos
    int currentStreak = 0;
    int longestStreak = 0;
    
    // Calcular tiempo por categoría
    Map<String, double> timeByCategory = {};
    
    // Procesar tareas
    for (var task in tasks) {
      final category = task.category;
      timeByCategory[category] = (timeByCategory[category] ?? 0) + (task.isCompleted ? 1.0 : 0.5);
    }
    
    // Procesar hábitos
    for (var habit in habits) {
      final category = habit.category;
      final progress = habit.getProgressPercentage();
      timeByCategory[category] = (timeByCategory[category] ?? 0) + progress * 2.0; // Asumimos 2 horas por hábito completado
    }
    
    // Procesar hobbies
    for (var hobby in hobbies) {
      final category = hobby.category;
      final timeInMinutes = _convertTimeToMinutes(hobby.time);
      timeByCategory[category] = (timeByCategory[category] ?? 0) + (timeInMinutes / 60.0);
    }
    
    // Calcular actividad diaria
    Map<int, int> activityByDay = {};
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      activityByDay[i] = 0;
    }
    
    // Contar actividades por día
    for (var task in tasks) {
      if (task.isCompleted) {
        final day = task.date.day;
        activityByDay[day] = (activityByDay[day] ?? 0) + 1;
      }
    }
    
    // Calcular rachas (simplificado)
    currentStreak = 4; // Valor de ejemplo
    longestStreak = 7; // Valor de ejemplo
    
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'timeByCategory': timeByCategory,
      'activityByDay': activityByDay,
    };
  }
  
  // Convertir formato de tiempo (HH:MM:SS) a minutos
  int _convertTimeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return hours * 60 + minutes + (seconds > 0 ? 1 : 0);
      }
    } catch (e) {
      print('Error al convertir tiempo: $e');
    }
    return 0;
  }
}

FirebaseFirestore db = FirebaseFirestore.instance;
