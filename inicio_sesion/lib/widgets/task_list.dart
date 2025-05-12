import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final String category;
  final bool isCompleted;
  final int priority; // 1: baja, 2: media, 3: alta

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
    this.category = 'General',
    this.isCompleted = false,
    this.priority = 2,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }

  // Crear desde Map de Firebase
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 2,
    );
  }

  // Crear copia con cambios
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    String? category,
    bool? isCompleted,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}
