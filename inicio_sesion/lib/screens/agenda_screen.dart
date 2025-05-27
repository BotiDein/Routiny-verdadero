import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/notification_manager.dart';
import 'task_form_screen.dart';
import '../services/local_storage_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late FirebaseService _firebaseService;
  final NotificationManager _notificationManager =
      NotificationManager(); // 🆕 NUEVO
  Map<String, List<Task>> _tasksByDate = {};
  Map<String, bool> _taskReminders = {}; // 🆕 NUEVO: Mapa de recordatorios
  bool _isLoading = true;
  Task? _lastDeletedTask; // Para almacenar la última tarea eliminada
  bool _lastDeletedTaskHadReminder = false; // 🆕 NUEVO

  @override
  void initState() {
    super.initState();
    // Obtener el ID del usuario actual o usar 'guest' si no hay usuario
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);
    _loadTasks();
    _loadReminders(); // 🆕 NUEVO
  }

  // 🆕 NUEVO: Cargar recordatorios desde SharedPreferences
  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('reminder_'));

      for (final key in keys) {
        final taskId = key.replaceFirst('reminder_', '');
        final hasReminder = prefs.getBool(key) ?? false;
        _taskReminders[taskId] = hasReminder;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  // 🆕 NUEVO: Verificar si una tarea tiene recordatorio
  bool _hasReminder(String taskId) {
    return _taskReminders[taskId] ?? false;
  }

  // Modificar el método _loadTasks para manejar mejor los errores
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Escuchar cambios en las tareas
      _firebaseService.getTasks().listen(
        (tasks) {
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
        },
        onError: (error) async {
          print('Error al cargar tareas: $error');
          // En caso de error, intentar cargar desde almacenamiento local
          try {
            final localStorageService = LocalStorageService();
            final tasks = await localStorageService.getTasks();

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

              // Mostrar mensaje al usuario
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Mostrando tareas guardadas localmente. Algunas funciones pueden estar limitadas sin conexión.',
                  ),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al cargar tareas: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      print('Error general al cargar tareas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tareas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      // La tarea se guardó correctamente, recargar recordatorios
      _loadReminders(); // 🆕 NUEVO
    }
  }

  void _onTaskTapped(Task task) {
    _navigateToTaskForm(task: task);
  }

  Future<void> _deleteTask(Task task) async {
    // Guardar la tarea antes de eliminarla para poder restaurarla
    _lastDeletedTask = task;
    _lastDeletedTaskHadReminder = _hasReminder(task.id); // 🆕 NUEVO

    try {
      // 🆕 NUEVO: Cancelar notificación si la tarea tenía recordatorio
      if (_lastDeletedTaskHadReminder) {
        await _notificationManager.cancelTaskNotification(task.id);

        // Remover del mapa de recordatorios
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('reminder_${task.id}');
        _taskReminders.remove(task.id);
      }

      await _firebaseService.deleteTask(task.id);

      // Mostrar SnackBar con opción de deshacer
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).clearSnackBars(); // Limpiar SnackBars anteriores
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastDeletedTaskHadReminder
                        ? 'Tarea y notificación eliminadas'
                        : 'Tarea eliminada',
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'DESHACER',
              onPressed: () {
                _undoDelete();
              },
            ),
            duration: const Duration(
              seconds: 5,
            ), // Dar tiempo suficiente para deshacer
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
        );
      }
    }
  }

  // Método para deshacer la eliminación
  Future<void> _undoDelete() async {
    if (_lastDeletedTask != null) {
      try {
        // Restaurar la tarea eliminada
        await _firebaseService.addTask(_lastDeletedTask!);

        // 🆕 NUEVO: Restaurar notificación si la tenía
        if (_lastDeletedTaskHadReminder) {
          try {
            await _notificationManager.scheduleTaskNotification(
              _lastDeletedTask!,
            );

            // Restaurar en SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('reminder_${_lastDeletedTask!.id}', true);
            _taskReminders[_lastDeletedTask!.id] = true;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Tarea y notificación restauradas'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            print('Error al restaurar notificación: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tarea restaurada (sin notificación)'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tarea restaurada')));
          }
        }

        // Limpiar la referencia a la tarea eliminada
        _lastDeletedTask = null;
        _lastDeletedTaskHadReminder = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al restaurar: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _firebaseService.toggleTaskCompletion(task.id, !task.isCompleted);

      // 🆕 NUEVO: Manejar notificaciones al completar/descompletar
      if (_hasReminder(task.id)) {
        if (!task.isCompleted) {
          // Si se está completando la tarea, cancelar notificación
          await _notificationManager.cancelTaskNotification(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Tarea completada - Notificación cancelada'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Si se está descompletando, reprogramar notificación si es futura
          final updatedTask = task.copyWith(isCompleted: false);
          if (updatedTask.date.isAfter(DateTime.now())) {
            await _notificationManager.scheduleTaskNotification(updatedTask);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Tarea reactivada - Notificación reprogramada'),
                  ],
                ),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
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

      // Ordenar las tareas para esta fecha por prioridad (alta, media, baja) y hora
      // y mover las completadas al final
      final tasksForDate = List<Task>.from(_tasksByDate[dateKey]!);
      tasksForDate.sort((a, b) {
        // Primero mover las tareas completadas al final
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;

        // Si ambas tienen el mismo estado de completado, ordenar por prioridad
        if (a.isCompleted == b.isCompleted) {
          // Ordenar por prioridad (3: alta, 2: media, 1: baja)
          if (a.priority != b.priority) {
            // Orden descendente para que la prioridad alta (3) aparezca primero
            return b.priority.compareTo(a.priority);
          }
          // Si tienen la misma prioridad, ordenar por hora
          return a.date.compareTo(b.date);
        }

        return 0;
      });

      // Agrupar tareas por prioridad
      final highPriorityTasks =
          tasksForDate.where((t) => !t.isCompleted && t.priority == 3).toList();
      final mediumPriorityTasks =
          tasksForDate.where((t) => !t.isCompleted && t.priority == 2).toList();
      final lowPriorityTasks =
          tasksForDate.where((t) => !t.isCompleted && t.priority == 1).toList();
      final completedTasks = tasksForDate.where((t) => t.isCompleted).toList();

      // Añadir encabezado y tareas de prioridad alta si hay alguna
      if (highPriorityTasks.isNotEmpty) {
        sections.add(
          _buildPriorityHeader('Prioridad Alta', Colors.red, bodyFontSize),
        );
        sections.add(SizedBox(height: screenHeight * 0.01));

        for (var task in highPriorityTasks) {
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
      }

      // Añadir encabezado y tareas de prioridad media si hay alguna
      if (mediumPriorityTasks.isNotEmpty) {
        sections.add(
          _buildPriorityHeader('Prioridad Media', Colors.orange, bodyFontSize),
        );
        sections.add(SizedBox(height: screenHeight * 0.01));

        for (var task in mediumPriorityTasks) {
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
      }

      // Añadir encabezado y tareas de prioridad baja si hay alguna
      if (lowPriorityTasks.isNotEmpty) {
        sections.add(
          _buildPriorityHeader('Prioridad Baja', Colors.green, bodyFontSize),
        );
        sections.add(SizedBox(height: screenHeight * 0.01));

        for (var task in lowPriorityTasks) {
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
      }

      // Añadir encabezado y tareas completadas si hay alguna
      if (completedTasks.isNotEmpty) {
        sections.add(
          _buildPriorityHeader('Completadas', Colors.grey, bodyFontSize),
        );
        sections.add(SizedBox(height: screenHeight * 0.01));

        for (var task in completedTasks) {
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

  // Método para construir los encabezados de prioridad
  Widget _buildPriorityHeader(String title, Color color, double fontSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: fontSize * 0.5,
        horizontal: fontSize * 0.7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(fontSize * 0.5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize * 0.9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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

    // 🆕 NUEVO: Verificar si tiene recordatorio
    final hasReminder = _hasReminder(task.id);

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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w500,
                                decoration:
                                    task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                color:
                                    task.isCompleted
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                          // 🆕 NUEVO: Indicador de recordatorio
                          if (hasReminder) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.notifications_active,
                              size: smallFontSize * 1.2,
                              color: const Color(0xFF4A90E2),
                            ),
                          ],
                        ],
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
                          // 🆕 NUEVO: Badge de recordatorio
                          if (hasReminder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Recordatorio',
                                style: TextStyle(
                                  fontSize: smallFontSize * 0.8,
                                  color: const Color(0xFF4A90E2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
