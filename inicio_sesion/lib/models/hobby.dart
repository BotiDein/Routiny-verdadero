import 'dart:convert';

class Hobby {
  final String id;
  final String name;
  final String icon;
  String time;
  final String weeklyGoal;
  final List<Map<String, dynamic>> registeredTimes;
  final List<int> activeDays;

  Hobby({
    required this.id,
    required this.name,
    required this.icon,
    this.time = '00:00:00',
    required this.weeklyGoal,
    required this.registeredTimes,
    required this.activeDays,
  });

  // Convertir Hobby a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'time': time,
      'weeklyGoal': weeklyGoal,
      'registeredTimes': registeredTimes.map((timeEntry) {
        final Map<String, dynamic> serializedEntry = Map.from(timeEntry);
        if (serializedEntry['date'] is DateTime) {
          serializedEntry['date'] = (serializedEntry['date'] as DateTime).toIso8601String();
        }
        return serializedEntry;
      }).toList(),
      'activeDays': activeDays,
    };
  }

  // Convertir Hobby a JSON
  String toJson() => jsonEncode(toMap());

  // Crear Hobby desde Map
  factory Hobby.fromMap(Map<String, dynamic> map) {
    // Procesar registeredTimes
    List<Map<String, dynamic>> processedTimes = [];
    if (map['registeredTimes'] != null) {
      processedTimes = (map['registeredTimes'] as List).map((timeEntry) {
        final Map<String, dynamic> entry = Map<String, dynamic>.from(timeEntry);
        if (entry['date'] is String) {
          entry['date'] = DateTime.parse(entry['date']);
        }
        return entry;
      }).cast<Map<String, dynamic>>().toList();
    }

    return Hobby(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? '',
      icon: map['icon'] ?? '😊',
      time: map['time'] ?? '00:00:00',
      weeklyGoal: map['weeklyGoal'] ?? '05:00:00',
      registeredTimes: processedTimes,
      activeDays: List<int>.from(map['activeDays'] ?? []),
    );
  }

  // Crear Hobby desde JSON
  factory Hobby.fromJson(String source) => Hobby.fromMap(jsonDecode(source));

  // Crear una copia del Hobby con cambios
  Hobby copyWith({
    String? id,
    String? name,
    String? icon,
    String? time,
    String? weeklyGoal,
    List<Map<String, dynamic>>? registeredTimes,
    List<int>? activeDays,
  }) {
    return Hobby(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      time: time ?? this.time,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      registeredTimes: registeredTimes ?? this.registeredTimes,
      activeDays: activeDays ?? this.activeDays,
    );
  }
}