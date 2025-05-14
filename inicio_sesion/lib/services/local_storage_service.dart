import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../models/hobby.dart';

class LocalStorageService {
  static const String _habitsKey = 'habits';
  static const String _tasksKey = 'tasks';
  static const String _hobbiesKey = 'hobbies';

  // -------------------- MÉTODOS PARA HÁBITOS --------------------

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

  Future<List<Habit>> getHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getStringList(_habitsKey) ?? [];

      if (habitsJson.isEmpty) return [];

      return habitsJson.map((json) {
        try {
          return Habit.fromJson(json);
        } catch (e) {
          print('Error al parsear hábito: $e');
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

  Future<List<Habit>> getHabitsForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final habits = await getHabits();
      return habits.where((habit) {
        return habit.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('Error al obtener hábitos por fecha: $e');
      return [];
    }
  }

  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == updatedHabit.id);

    if (index != -1) {
      habits[index] = updatedHabit;
      await saveHabits(habits);
    } else {
      throw Exception('Hábito no encontrado');
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == habitId);
    await saveHabits(habits);
  }

  // -------------------- MÉTODOS PARA TAREAS --------------------

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

  Future<List<Task>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList(_tasksKey) ?? [];

      return tasksJson.map((json) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          map['date'] = DateTime.parse(map['date']);
          map['createdAt'] = DateTime.parse(map['createdAt']);
          return Task.fromMap(map);
        } catch (e) {
          print('Error al parsear tarea: $e');
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

  Future<List<Task>> getTasksForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final tasks = await getTasks();
      return tasks.where((task) {
        final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        return taskDate.isAtSameMomentAs(start) || 
               taskDate.isAtSameMomentAs(end) || 
               (taskDate.isAfter(start) && taskDate.isBefore(end));
      }).toList();
    } catch (e) {
      print('Error al obtener tareas por fecha: $e');
      return [];
    }
  }

  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  Future<void> updateTask(Task updatedTask) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);

    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    } else {
      throw Exception('Tarea no encontrada');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);

    if (index != -1) {
      final task = tasks[index];
      tasks[index] = task.copyWith(isCompleted: isCompleted);
      await saveTasks(tasks);
    } else {
      throw Exception('Tarea no encontrada');
    }
  }

  // -------------------- MÉTODOS PARA HOBBIES --------------------

  Future<void> saveHobbies(List<Hobby> hobbies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hobbiesJson = hobbies.map((hobby) => hobby.toJson()).toList();
      await prefs.setStringList(_hobbiesKey, hobbiesJson);
      print('Hobbies guardados: ${hobbiesJson.length}');
    } catch (e) {
      print('Error al guardar hobbies: $e');
      throw Exception('No se pudieron guardar los hobbies: $e');
    }
  }

  Future<List<Hobby>> getHobbies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hobbiesJson = prefs.getStringList(_hobbiesKey) ?? [];

      return hobbiesJson.map((json) {
        try {
          return Hobby.fromJson(json);
        } catch (e) {
          print('Error al parsear hobby: $e');
          return Hobby(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Hobby (error)',
            icon: '😊',
            time: '00:00:00',
            weeklyGoal: '05:00:00',
            registeredTimes: [],
            activeDays: [],
          );
        }
      }).toList();
    } catch (e) {
      print('Error al obtener hobbies: $e');
      return [];
    }
  }

  Future<void> addHobby(Hobby hobby) async {
    final hobbies = await getHobbies();
    hobbies.add(hobby);
    await saveHobbies(hobbies);
  }

  Future<void> updateHobby(Hobby updatedHobby) async {
    final hobbies = await getHobbies();
    final index = hobbies.indexWhere((h) => h.id == updatedHobby.id);

    if (index != -1) {
      hobbies[index] = updatedHobby;
      await saveHobbies(hobbies);
    } else {
      throw Exception('Hobby no encontrado');
    }
  }

  Future<void> deleteHobby(String hobbyId) async {
    final hobbies = await getHobbies();
    hobbies.removeWhere((h) => h.id == hobbyId);
    await saveHobbies(hobbies);
  }
}
