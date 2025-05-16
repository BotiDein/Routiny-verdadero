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
      'registeredTimes': registeredTimes.map((e) => {
        'date': (e['date'] as DateTime).toIso8601String(),
        'time': e['time'],
      }).toList(),
      'activeDays': activeDays,
    };
  }

  // Convertir Hobby a JSON
  String toJson() => jsonEncode(toMap());

  // Crear Hobby desde Map
  factory Hobby.fromMap(Map<String, dynamic> map) {
    return Hobby(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      time: map['time'],
      weeklyGoal: map['weeklyGoal'],
      registeredTimes: (map['registeredTimes'] as List)
          .map((e) => {
                'date': DateTime.parse(e['date']),
                'time': e['time'],
              })
          .toList(),
      activeDays: List<int>.from(map['activeDays']),
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