import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import 'task_form_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late FirebaseService _firebaseService;
  Map<String, List<Task>> _tasksByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Obtener el ID del usuario actual o usar 'guest' si no hay usuario
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    // Escuchar cambios en las tareas
    _firebaseService.getTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          // Agrupar tareas por fecha
          _tasksByDate = {};
          for (var task in tasks) {
            final dateKey = DateFormat('yyyy-MM-dd').format(task.date);
            if (!_tasksByDate.containsKey(dateKey)) {
              _tasksByDate[dateKey] = [];
            }
            _tasksByDate[dateKey]!.add(task);
          }
          _isLoading = false;
        });
      }
    });
  }

  void _navigateToTaskForm({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskFormScreen(task: task, isEditing: task != null),
      ),
    );

    if (result == true) {
      // La tarea se guardó correctamente, no necesitamos hacer nada
      // ya que estamos escuchando cambios en Firestore
    }
  }

  void _onTaskTapped(Task task) {
    _navigateToTaskForm(task: task);
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _firebaseService.deleteTask(task.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _firebaseService.toggleTaskCompletion(task.id, !task.isCompleted);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Calculamos valores relativos basados en el tamaño de la pantalla
    final horizontalPadding = screenWidth * 0.04; // 4% del ancho de pantalla
    final headerFontSize = screenWidth * 0.045; // 4.5% para encabezados
    final bodyFontSize = screenWidth * 0.04; // 4% para texto normal
    final smallFontSize = screenWidth * 0.035; // 3.5% para texto pequeño
    final mediumIconSize = screenWidth * 0.05; // 5% para iconos medianos

    return Scaffold(
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasksByDate.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: screenWidth * 0.2,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay tareas pendientes',
                        style: TextStyle(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el botón + para añadir una tarea',
                        style: TextStyle(
                          fontSize: smallFontSize,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.025),

                        // Construir secciones por fecha
                        ..._buildTaskSections(
                          headerFontSize,
                          bodyFontSize,
                          smallFontSize,
                          mediumIconSize,
                          screenHeight,
                        ),

                        // Espacio adicional al final
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0047AB), // Azul oscuro
        child: Icon(Icons.add, color: Colors.white, size: mediumIconSize),
        onPressed: () => _navigateToTaskForm(),
      ),
    );
  }

  List<Widget> _buildTaskSections(
    double headerFontSize,
    double bodyFontSize,
    double smallFontSize,
    double mediumIconSize,
    double screenHeight,
  ) {
    // Ordenar las fechas
    final sortedDates =
        _tasksByDate.keys.toList()..sort((a, b) => a.compareTo(b));

    final List<Widget> sections = [];
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final tomorrow = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(now.year, now.month, now.day + 1));

    for (var dateKey in sortedDates) {
      // Determinar el título de la sección
      String sectionTitle;
      if (dateKey == today) {
        sectionTitle = 'Hoy';
      } else if (dateKey == tomorrow) {
        sectionTitle = 'Mañana';
      } else {
        // Convertir la clave de fecha a DateTime
        final dateParts = dateKey.split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        sectionTitle = DateFormat('d MMMM yyyy', 'es_ES').format(date);
      }

      // Añadir la sección de fecha
      sections.add(_buildDateSection(sectionTitle, headerFontSize));
      sections.add(SizedBox(height: screenHeight * 0.015));

      // Añadir las tareas para esta fecha
      for (var task in _tasksByDate[dateKey]!) {
        sections.add(
          _buildTaskItem(
            task: task,
            bodyFontSize: bodyFontSize,
            smallFontSize: smallFontSize,
            iconSize: mediumIconSize,
          ),
        );
        sections.add(SizedBox(height: screenHeight * 0.02));
      }

      // Añadir espacio entre secciones
      sections.add(SizedBox(height: screenHeight * 0.01));
    }

    return sections;
  }

  // Método para construir las secciones de fecha
  Widget _buildDateSection(String date, double fontSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.7),
      decoration: BoxDecoration(
        color: const Color(0xFFADD8E6), // Azul claro
        borderRadius: BorderRadius.circular(fontSize * 0.5),
      ),
      child: Text(
        date,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Método para construir los items de tareas
  Widget _buildTaskItem({
    required Task task,
    required double bodyFontSize,
    required double smallFontSize,
    required double iconSize,
  }) {
    // Determinar el icono según la categoría
    IconData taskIcon;
    switch (task.category) {
      case 'Trabajo':
        taskIcon = Icons.work;
        break;
      case 'Personal':
        taskIcon = Icons.person;
        break;
      case 'Salud':
        taskIcon = Icons.favorite;
        break;
      case 'Educación':
        taskIcon = Icons.school;
        break;
      case 'Finanzas':
        taskIcon = Icons.attach_money;
        break;
      default:
        taskIcon = Icons.assignment;
    }

    // Determinar el color según la prioridad
    Color priorityColor;
    switch (task.priority) {
      case 1:
        priorityColor = Colors.green;
        break;
      case 3:
        priorityColor = Colors.red;
        break;
      default:
        priorityColor = Colors.orange;
    }

    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteTask(task);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTaskTapped(task),
          borderRadius: BorderRadius.circular(bodyFontSize * 0.5),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: bodyFontSize * 0.5),
            child: Row(
              children: [
                // Checkbox para marcar como completada
                GestureDetector(
                  onTap: () => _toggleTaskCompletion(task),
                  child: Container(
                    padding: EdgeInsets.all(bodyFontSize * 0.3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          task.isCompleted ? priorityColor : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? priorityColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child:
                        task.isCompleted
                            ? Icon(
                              Icons.check,
                              size: iconSize * 0.7,
                              color: Colors.white,
                            )
                            : const SizedBox(width: 10, height: 10),
                  ),
                ),
                const SizedBox(width: 12),
                // Contenedor circular para el icono
                Container(
                  padding: EdgeInsets.all(bodyFontSize * 0.6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: bodyFontSize * 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(taskIcon, size: iconSize),
                ),
                const SizedBox(width: 12),
                // El texto ocupa el espacio disponible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w500,
                          decoration:
                              task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                          color: task.isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey[700],
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: smallFontSize,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(task.date),
                            style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.priority == 1
                                  ? 'Baja'
                                  : task.priority == 2
                                  ? 'Media'
                                  : 'Alta',
                              style: TextStyle(
                                fontSize: smallFontSize * 0.9,
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono de flecha a la derecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: smallFontSize,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
