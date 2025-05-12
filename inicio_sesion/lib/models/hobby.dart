import 'package:cloud_firestore/cloud_firestore.dart';

class Hobby {
  final String id;
  final String name;
  final String icon;
  final String category;
  final String time; // Tiempo total registrado
  final String weeklyGoal; // Meta semanal
  final List<Map<String, dynamic>> registeredTimes; // Lista de tiempos registrados
  final List<int> activeDays; // Días con actividad (0-6, donde 0 es domingo)
  final DateTime createdAt;

  Hobby({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.time = '00:00:00',
    this.weeklyGoal = '05:00:00',
    required this.registeredTimes,
    required this.activeDays,
    required this.createdAt,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'category': category,
      'time': time,
      'weeklyGoal': weeklyGoal,
      'registeredTimes': registeredTimes,
      'activeDays': activeDays,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Crear desde Map de Firebase
  factory Hobby.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> times = [];
    if (map['registeredTimes'] != null) {
      times = List<Map<String, dynamic>>.from(
        map['registeredTimes'].map((x) => Map<String, dynamic>.from(x)),
      );
    }

    return Hobby(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '😊',
      category: map['category'] ?? 'Música',
      time: map['time'] ?? '00:00:00',
      weeklyGoal: map['weeklyGoal'] ?? '05:00:00',
      registeredTimes: times,
      activeDays: List<int>.from(map['activeDays'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Calcular el porcentaje de progreso hacia la meta semanal
  double getProgressPercentage() {
    // Convertir tiempo a minutos para comparar
    final goalMinutes = _convertTimeToMinutes(weeklyGoal);
    final currentMinutes = _convertTimeToMinutes(time);
    if (goalMinutes == 0) return 0.0;
    return (currentMinutes / goalMinutes).clamp(0.0, 1.0);
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

  // Verificar si el hobby tiene actividad registrada para el día actual
  bool hasActivityToday() {
    final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
    return activeDays.contains(today);
  }

  // Obtener el tiempo registrado para una fecha específica
  String getTimeForDate(DateTime date) {
    final dateString = '${date.year}-${date.month}-${date.day}';
    for (var entry in registeredTimes) {
      if (entry['date'] == dateString) {
        return entry['time'] ?? '00:00:00';
      }
    }
    return '00:00:00';
  }
}
