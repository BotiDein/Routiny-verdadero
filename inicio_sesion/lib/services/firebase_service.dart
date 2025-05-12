import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
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
  Future<List<Map<String, dynamic>>> getHabits() async {
    try {
      // Intentar obtener hábitos de Firebase
      final snapshot = await _habitsCollection.get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay hábitos en Firebase, usar datos de ejemplo
        return _getDemoHabits();
      }
      
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error al obtener hábitos: $e');
      // En caso de error, devolver datos de ejemplo
      return _getDemoHabits();
    }
  }
  
  // Datos de ejemplo para hábitos (en caso de que no haya datos en Firebase)
  List<Map<String, dynamic>> _getDemoHabits() {
    return [
      {
        'id': '1',
        'name': 'Salir a correr',
        'category': 'Ejercicio',
        'type': 'count',
        'option': 'Al menos',
        'goal': 30,
        'amount': 5,
        'current': 20,
        'description': 'Correr al menos 30 minutos diarios',
        'days': [0, 1, 2, 1, 0, 1, 0], // 0: no registrado, 1: parcial, 2: completado
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
      },
      {
        'id': '2',
        'name': 'Meditar',
        'category': 'Salud',
        'type': 'time',
        'option': 'Al menos',
        'goal': '00:15:00',
        'current': '00:10:00',
        'description': 'Meditar al menos 15 minutos diarios',
        'days': [2, 0, 2, 2, 1, 0, 0],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 20))),
      },
      {
        'id': '3',
        'name': 'Leer',
        'category': 'Educación',
        'type': 'boolean',
        'current': true,
        'description': 'Leer al menos un capítulo diario',
        'days': [2, 2, 0, 2, 2, 0, 0],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
      },
    ];
  }
  
  // MÉTODOS PARA HOBBIES
  
  // Obtener todos los hobbies
  Future<List<Map<String, dynamic>>> getHobbies() async {
    try {
      final snapshot = await _hobbiesCollection.get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay hobbies en Firebase, usar datos de ejemplo
        return _getDemoHobbies();
      }
      
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error al obtener hobbies: $e');
      // En caso de error, devolver datos de ejemplo
      return _getDemoHobbies();
    }
  }
  
  // Datos de ejemplo para hobbies (en caso de que no haya datos en Firebase)
  List<Map<String, dynamic>> _getDemoHobbies() {
    return [
      {
        'id': '1',
        'name': 'Tocar guitarra',
        'icon': '🎸',
        'category': 'Música',
        'time': '03:30:00',
        'weeklyGoal': '05:00:00',
        'registeredTimes': [
          {'date': '2025-4-15', 'time': '01:00:00'},
          {'date': '2025-4-17', 'time': '01:30:00'},
          {'date': '2025-4-19', 'time': '01:00:00'},
        ],
        'activeDays': [1, 3, 5], // Lunes, Miércoles, Viernes
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
      },
      {
        'id': '2',
        'name': 'Pintar',
        'icon': '🎨',
        'category': 'Arte',
        'time': '02:45:00',
        'weeklyGoal': '04:00:00',
        'registeredTimes': [
          {'date': '2025-4-14', 'time': '01:15:00'},
          {'date': '2025-4-18', 'time': '01:30:00'},
        ],
        'activeDays': [0, 4], // Domingo, Jueves
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
      },
    ];
  }
}

FirebaseFirestore db = FirebaseFirestore.instance;
