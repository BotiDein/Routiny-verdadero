import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  // Constructor que acepta un userId opcional
  FirebaseService([String? uid])
    : userId = uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // Colección de tareas del usuario
  CollectionReference get _tasksCollection =>
      _firestore.collection('users').doc(userId).collection('tasks');

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
    // Último día del mes
    final lastDay = DateTime(year, month + 1, 0);

    final snapshot =
        await _tasksCollection
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
            .get();

    // Extraer fechas únicas
    final Set<String> uniqueDates = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateString = '${date.year}-${date.month}-${date.day}';
      uniqueDates.add(dateString);
    }

    // Convertir a lista de DateTime
    return uniqueDates.map((dateStr) {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList();
  }
}

FirebaseFirestore db = FirebaseFirestore.instance;
