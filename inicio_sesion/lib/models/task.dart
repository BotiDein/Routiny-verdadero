class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final bool isCompleted;
  final String? category;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.isCompleted = false,
    this.category,
    required this.createdAt,
  });

  // Crear una copia de la tarea con algunos campos modificados
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    String? category,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convertir la tarea a un mapa para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Crear una tarea desde un mapa
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isCompleted: map['isCompleted'] ?? false,
      category: map['category'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}