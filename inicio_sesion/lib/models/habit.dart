import 'dart:convert';

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
    this.goal,
    this.current,
    this.amount = 1,
    required this.days,
    required this.createdAt,
  });

  // Convertir Habit a Map
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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convertir Habit a JSON
  String toJson() => json.encode(toMap());

  // Crear Habit desde Map
  factory Habit.fromMap(Map<String, dynamic> map) {
    // Asegurar que days sea una lista de enteros
    List<int> daysList = [];
    if (map['days'] != null) {
      if (map['days'] is List) {
        daysList = List<int>.from(
          (map['days'] as List).map((item) => item is int ? item : 0),
        );
      }
    }
    
    // Si la lista está vacía o tiene menos de 7 elementos, rellenarla
    while (daysList.length < 7) {
      daysList.add(0);
    }

    // Manejar diferentes tipos de datos para current
    dynamic currentValue = map['current'];
    if (map['type'] == 'count') {
      // Asegurar que current sea un entero para tipo 'count'
      if (currentValue is int) {
        // Ya es un entero, no hacer nada
      } else if (currentValue is String) {
        // Intentar convertir de string a entero
        currentValue = int.tryParse(currentValue) ?? 0;
      } else {
        // Valor por defecto
        currentValue = 0;
      }
    } else if (map['type'] == 'time') {
      // Asegurar que current sea un string para tipo 'time'
      if (currentValue is String) {
        // Ya es un string, no hacer nada
      } else {
        // Valor por defecto
        currentValue = '00:00:00';
      }
    } else if (map['type'] == 'boolean') {
      // Asegurar que current sea un booleano para tipo 'boolean'
      if (currentValue is bool) {
        // Ya es un booleano, no hacer nada
      } else {
        // Convertir a booleano
        currentValue = currentValue == true || currentValue == 'true';
      }
    }

    // Manejar diferentes tipos de datos para goal
    dynamic goalValue = map['goal'];
    if (map['type'] == 'count') {
      // Asegurar que goal sea un entero para tipo 'count'
      if (goalValue is int) {
        // Ya es un entero, no hacer nada
      } else if (goalValue is String) {
        // Intentar convertir de string a entero
        goalValue = int.tryParse(goalValue) ?? 0;
      } else {
        // Valor por defecto
        goalValue = 0;
      }
    } else if (map['type'] == 'time') {
      // Asegurar que goal sea un string para tipo 'time'
      if (goalValue is String) {
        // Ya es un string, no hacer nada
      } else {
        // Valor por defecto
        goalValue = '00:00:00';
      }
    }

    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      type: map['type'] ?? 'count',
      option: map['option'] ?? 'Al menos',
      goal: goalValue,
      current: currentValue,
      amount: map['amount'] is int ? map['amount'] : 1,
      days: daysList,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  // Crear Habit desde JSON
  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));

  // Crear una copia de Habit con algunos campos actualizados
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
    );
  }
}
