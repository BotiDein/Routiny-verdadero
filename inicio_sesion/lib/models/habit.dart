import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final String type;
  final String option;
  final dynamic goal;
  final dynamic current;
  final int amount;
  final List<int> days;
  final DateTime createdAt;
  final Map<String, int> completedDates;
  final Map<String, String> registeredTimes;

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.type,
    this.option = 'Sin objetivo',
    this.goal,
    this.current,
    this.amount = 1,
    required this.days,
    required this.createdAt,
    Map<String, int>? completedDates,
    Map<String, String>? registeredTimes,
  })  : this.completedDates = completedDates ?? {},
        this.registeredTimes = registeredTimes ?? {};

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? type,
    String? option,
    dynamic goal,
    dynamic current,
    int? amount,
    List<int>? days,
    DateTime? createdAt,
    Map<String, int>? completedDates,
    Map<String, String>? registeredTimes,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      option: option ?? this.option,
      goal: goal ?? this.goal,
      current: current ?? this.current,
      amount: amount ?? this.amount,
      days: days ?? List<int>.from(this.days),
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? Map<String, int>.from(this.completedDates),
      registeredTimes: registeredTimes ?? Map<String, String>.from(this.registeredTimes),
    );
  }

  /// Convertir a Map (sin Timestamp, apto para JSON/local storage)
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
      'createdAt': createdAt.toIso8601String(), // 🔁 serializable como String
      'completedDates': completedDates,
      'registeredTimes': registeredTimes,
    };
  }

  /// Convertir a JSON string
  String toJson() => json.encode(toMap());

  /// Crear desde Map
  factory Habit.fromMap(Map<String, dynamic> map) {
    List<int> daysList = [];
    if (map['days'] != null) {
      daysList = List<int>.from((map['days'] as List).map((e) => e is int ? e : 0));
    }
    while (daysList.length < 7) {
      daysList.add(0);
    }

    dynamic currentValue = _parseCurrent(map['current'], map['type']);
    dynamic goalValue = _parseGoal(map['goal'], map['type']);

    DateTime createdDate;
    final rawDate = map['createdAt'];
    if (rawDate is String) {
      createdDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is Timestamp) {
      createdDate = rawDate.toDate();
    } else {
      createdDate = DateTime.now();
    }

    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      type: map['type'] ?? 'count',
      option: map['option'] ?? 'Sin objetivo',
      goal: goalValue,
      current: currentValue,
      amount: map['amount'] is int ? map['amount'] : 1,
      days: daysList,
      createdAt: createdDate,
      completedDates: map['completedDates'] != null
          ? Map<String, int>.from(map['completedDates'])
          : {},
      registeredTimes: map['registeredTimes'] != null
          ? Map<String, String>.from(map['registeredTimes'])
          : {},
    );
  }

  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));

  static dynamic _parseCurrent(dynamic current, String? type) {
    switch (type) {
      case 'count':
        if (current is int) return current;
        if (current is String) return int.tryParse(current) ?? 0;
        return 0;
      case 'time':
        return current is String ? current : '00:00:00';
      case 'boolean':
        return current == true || current == 'true';
      default:
        return current;
    }
  }

  static dynamic _parseGoal(dynamic goal, String? type) {
    switch (type) {
      case 'count':
        if (goal is int) return goal;
        if (goal is String) return int.tryParse(goal) ?? 0;
        return 0;
      case 'time':
        return goal is String ? goal : '00:00:00';
      default:
        return goal;
    }
  }
}
