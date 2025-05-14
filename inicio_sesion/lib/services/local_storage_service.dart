import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class LocalStorageService {
  static const String _habitsKey = 'habits';
  
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
}
