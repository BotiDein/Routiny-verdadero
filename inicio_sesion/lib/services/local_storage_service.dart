import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/task.dart';

class LocalStorageService {
  static const String _habitsKey = 'habits';
  static const String _tasksKey = 'tasks';
  
  // MÉTODOS PARA HÁBITOS
  
  // Guardar hábitos en SharedPreferences
  Future<void> saveHabits(List<Habit> habits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = habits.map((habit) => habit.toJson()).toList();
      await prefs.setStringList(_habitsKey, habitsJson);
    } catch (e) {
      print('Error al guardar hábitos: $e');
      throw Exception('No se pudieron guardar los hábitos: $e');
    }
  }
  
  // Obtener hábitos de SharedPreferences
  Future<List<Habit>> getHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getStringList(_habitsKey) ?? [];
      
      if (habitsJson.isEmpty) {
        return [];
      }
      
      return habitsJson.map((json) {
        try {
          return Habit.fromJson(json);
        } catch (e) {
          print('Error al parsear hábito: $e');
          // Devolver un hábito por defecto en caso de error
          return Habit(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Hábito (error)',
            description: 'Hubo un error al cargar este hábito',
            category: 'General',
            type: 'count',
            days: [0, 0, 0, 0, 0, 0, 0],
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      print('Error al obtener hábitos: $e');
      return [];
    }
  }
  
  // Obtener hábitos para un rango de fechas específico
  Future<List<Habit>> getHabitsForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final habits = await getHabits();
      
      // Filtrar hábitos creados dentro del rango de fechas o antes
      return habits.where((habit) {
        // Incluir hábitos creados antes o durante el período
        return habit.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('Error al obtener hábitos para rango de fechas: $e');
      return [];
    }
  }
  
  // Añadir un nuevo hábito
  Future<void> addHabit(Habit habit) async {
    try {
      final habits = await getHabits();
      habits.add(habit);
      await saveHabits(habits);
    } catch (e) {
      print('Error al añadir hábito: $e');
      throw Exception('No se pudo añadir el hábito: $e');
    }
  }
  
  // Actualizar un hábito existente
  Future<void> updateHabit(Habit updatedHabit) async {
    try {
      final habits = await getHabits();
      final index = habits.indexWhere((h) => h.id == updatedHabit.id);
      
      if (index != -1) {
        habits[index] = updatedHabit;
        await saveHabits(habits);
      } else {
        throw Exception('Hábito no encontrado');
      }
    } catch (e) {
      print('Error al actualizar hábito: $e');
      throw Exception('No se pudo actualizar el hábito: $e');
    }
  }
  
  // Eliminar un hábito
  Future<void> deleteHabit(String habitId) async {
    try {
      final habits = await getHabits();
      habits.removeWhere((h) => h.id == habitId);
      await saveHabits(habits);
    } catch (e) {
      print('Error al eliminar hábito: $e');
      throw Exception('No se pudo eliminar el hábito: $e');
    }
  }
  
  // MÉTODOS PARA TAREAS
  
  // Guardar tareas en SharedPreferences
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => jsonEncode(task.toMap())).toList();
      await prefs.setStringList(_tasksKey, tasksJson);
    } catch (e) {
      print('Error al guardar tareas: $e');
      throw Exception('No se pudieron guardar las tareas: $e');
    }
  }
  
  // Obtener tareas de SharedPreferences
  Future<List<Task>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList(_tasksKey) ?? [];
      
      if (tasksJson.isEmpty) {
        return [];
      }
      
      return tasksJson.map((json) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          
          // Convertir las fechas de string a DateTime
          if (map['date'] is String) {
            map['date'] = DateTime.parse(map['date']);
          }
          if (map['createdAt'] is String) {
            map['createdAt'] = DateTime.parse(map['createdAt']);
          }
          
          return Task.fromMap(map);
        } catch (e) {
          print('Error al parsear tarea: $e');
          // Devolver una tarea por defecto en caso de error
          return Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Tarea (error)',
            description: 'Hubo un error al cargar esta tarea',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      print('Error al obtener tareas: $e');
      return [];
    }
  }
  
  // Obtener tareas para un rango de fechas específico
  Future<List<Task>> getTasksForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final tasks = await getTasks();
      
      // Filtrar tareas dentro del rango de fechas
      return tasks.where((task) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        
        return taskDate.isAtSameMomentAs(start) || 
               taskDate.isAtSameMomentAs(end) || 
               (taskDate.isAfter(start) && taskDate.isBefore(end));
      }).toList();
    } catch (e) {
      print('Error al obtener tareas para rango de fechas: $e');
      return [];
    }
  }
  
  // Añadir una nueva tarea
  Future<void> addTask(Task task) async {
    try {
      final tasks = await getTasks();
      tasks.add(task);
      await saveTasks(tasks);
    } catch (e) {
      print('Error al añadir tarea: $e');
      throw Exception('No se pudo añadir la tarea: $e');
    }
  }
  
  // Actualizar una tarea existente
  Future<void> updateTask(Task updatedTask) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((t) => t.id == updatedTask.id);
      
      if (index != -1) {
        tasks[index] = updatedTask;
        await saveTasks(tasks);
      } else {
        throw Exception('Tarea no encontrada');
      }
    } catch (e) {
      print('Error al actualizar tarea: $e');
      throw Exception('No se pudo actualizar la tarea: $e');
    }
  }
  
  // Eliminar una tarea
  Future<void> deleteTask(String taskId) async {
    try {
      final tasks = await getTasks();
      tasks.removeWhere((t) => t.id == taskId);
      await saveTasks(tasks);
    } catch (e) {
      print('Error al eliminar tarea: $e');
      throw Exception('No se pudo eliminar la tarea: $e');
    }
  }
  
  // Marcar tarea como completada
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((t) => t.id == taskId);
      
      if (index != -1) {
        final task = tasks[index];
        tasks[index] = task.copyWith(isCompleted: isCompleted);
        await saveTasks(tasks);
      } else {
        throw Exception('Tarea no encontrada');
      }
    } catch (e) {
      print('Error al cambiar estado de tarea: $e');
      throw Exception('No se pudo cambiar el estado de la tarea: $e');
    }
  }
}
