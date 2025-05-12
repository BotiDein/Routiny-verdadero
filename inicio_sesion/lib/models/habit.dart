import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final String type; // 'count', 'time', 'boolean'
  final String option; // 'Al menos', 'Marca de', 'Exactamente', 'Sin objetivo'
  final dynamic goal; // puede ser int o String dependiendo del tipo
  final dynamic current; // puede ser int, String o bool dependiendo del tipo
  final int amount;
  final List<int> days; // 0: no registrado, 1: parcial, 2: completado
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    this.option = 'Al menos',
    this.goal = 0,
    this.current = 0,
    this.amount = 0,
    required this.days,
    required this.createdAt,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'type': type,
      'option': option,
      'goal': goal,
      'current': current,
      'amount': amount,
      'days': days,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Crear desde Map de Firebase
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Ejercicio',
      type: map['type'] ?? 'count',
      option: map['option'] ?? 'Al menos',
      goal: map['goal'] ?? 0,
      current: map['current'] ?? 0,
      amount: map['amount'] ?? 0,
      days: List<int>.from(map['days'] ?? [0, 0, 0, 0, 0, 0, 0]),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Calcular el porcentaje de progreso
  double getProgressPercentage() {
    if (type == 'boolean') {
      return current == true ? 1.0 : 0.0;
    } else if (type == 'count') {
      if (goal == 0) return 0.0;
      return (current / goal).clamp(0.0, 1.0);
    } else if (type == 'time') {
      // Convertir tiempo a minutos para comparar
      final goalMinutes = _convertTimeToMinutes(goal.toString());
      final currentMinutes = _convertTimeToMinutes(current.toString());
      if (goalMinutes == 0) return 0.0;
      return (currentMinutes / goalMinutes).clamp(0.0, 1.0);
    }
    return 0.0;
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

  // Verificar si el hábito está completado para el día actual
  bool isCompletedToday() {
    final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
    return days[today] == 2;
  }

  // Verificar si el hábito está parcialmente completado para el día actual
  bool isPartiallyCompletedToday() {
    final today = DateTime.now().weekday % 7;
    return days[today] == 1;
  }
}
