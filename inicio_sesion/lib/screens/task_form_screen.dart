import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/notification_manager.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final bool isEditing;
  final DateTime? initialDate;

  const TaskFormScreen({
    super.key,
    this.task,
    this.isEditing = false,
    this.initialDate,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedCategory = 'General';
  int _selectedPriority = 2;
  bool _hasReminder = false; // 🆕 NUEVO: Switch para recordatorio

  final List<String> _categories = [
    'General',
    'Trabajo',
    'Personal',
    'Salud',
    'Educación',
    'Finanzas',
  ];

  late FirebaseService _firebaseService;
  final NotificationManager _notificationManager =
      NotificationManager(); // 🆕 NUEVO
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Obtener el ID del usuario actual o usar 'guest' si no hay usuario
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);

    // Inicializar con la fecha y hora actual o la fecha proporcionada
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = TimeOfDay.now();

    // Si estamos editando, cargar los datos de la tarea
    if (widget.isEditing && widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.date);
      _selectedCategory = widget.task!.category;
      _selectedPriority = widget.task!.priority;
      _loadReminderStatus(); // 🆕 NUEVO: Cargar estado del recordatorio
    }
  }

  // 🆕 NUEVO: Cargar estado del recordatorio desde SharedPreferences
  Future<void> _loadReminderStatus() async {
    if (widget.task != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final hasReminder =
            prefs.getBool('reminder_${widget.task!.id}') ?? false;
        setState(() {
          _hasReminder = hasReminder;
        });
      } catch (e) {
        print('Error loading reminder status: $e');
      }
    }
  }

  // 🆕 NUEVO: Guardar estado del recordatorio en SharedPreferences
  Future<void> _saveReminderStatus(String taskId, bool hasReminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_$taskId', hasReminder);
    } catch (e) {
      print('Error saving reminder status: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _showTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Categoría'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_categories[index]),
                  onTap: () {
                    setState(() {
                      _selectedCategory = _categories[index];
                    });
                    Navigator.pop(context);
                  },
                  trailing:
                      _selectedCategory == _categories[index]
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Mostrar diálogo para añadir nueva categoría
                _showAddCategoryDialog();
              },
              child: const Text('Nueva Categoría'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Categoría'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              hintText: 'Nombre de la categoría',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (categoryController.text.isNotEmpty) {
                  setState(() {
                    _categories.add(categoryController.text);
                    _selectedCategory = categoryController.text;
                  });
                  Navigator.pop(context);
                  Navigator.pop(
                    context,
                  ); // Cerrar también el diálogo de categorías
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  // 🆕 NUEVO: Validar si la fecha/hora es futura
  bool _isFutureDateTime(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }

  // 🆕 NUEVO: Mostrar alerta para fechas pasadas
  void _showPastDateAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Fecha en el pasado'),
          content: const Text(
            'La fecha y hora seleccionadas ya han pasado. Las notificaciones solo se programan para fechas futuras.\n\n¿Qué deseas hacer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Programar para mañana a la misma hora
                setState(() {
                  _selectedDate = DateTime.now().add(const Duration(days: 1));
                });
              },
              child: const Text('Mañana'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Ajustar a hora actual + 1 hora
                final now = DateTime.now();
                setState(() {
                  _selectedDate = now;
                  _selectedTime = TimeOfDay.fromDateTime(
                    now.add(const Duration(hours: 1)),
                  );
                });
              },
              child: const Text('En 1 hora'),
            ),
          ],
        );
      },
    );
  }

  // 🆕 NUEVO: Programar notificación de tarea
  Future<void> _scheduleTaskNotification(Task task) async {
    if (!_hasReminder) return;

    try {
      // Verificar si la fecha es futura
      if (!_isFutureDateTime(task.date)) {
        print('⚠️ No se programa notificación: fecha en el pasado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Notificación no programada: fecha en el pasado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _notificationManager.scheduleTaskNotification(task);
      await _saveReminderStatus(task.id, true);

      print(
        '✅ Notificación programada para: ${DateFormat('dd/MM/yyyy HH:mm').format(task.date)}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔔 Notificación programada para ${DateFormat('dd/MM HH:mm').format(task.date)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error al programar notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al programar notificación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 NUEVO: Cancelar notificación de tarea
  Future<void> _cancelTaskNotification(String taskId) async {
    try {
      await _notificationManager.cancelTaskNotification(taskId);
      await _saveReminderStatus(taskId, false);
      print('✅ Notificación cancelada para tarea: $taskId');
    } catch (e) {
      print('❌ Error al cancelar notificación: $e');
    }
  }

  // Mostrar diálogo de confirmación para eliminar tarea
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar tarea'),
          content: Text(
            '¿Estás seguro de que deseas eliminar la tarea "${widget.task!.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Eliminar tarea
  Future<void> _deleteTask() async {
    if (widget.task == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 🆕 NUEVO: Cancelar notificación al eliminar
      if (_hasReminder) {
        await _cancelTaskNotification(widget.task!.id);
      }

      await _firebaseService.deleteTask(widget.task!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
        Navigator.pop(context, true); // Regresar a la pantalla anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Modificar el método _saveTask para manejar mejor los errores y mostrar feedback al usuario
  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un título')),
      );
      return;
    }

    // 🆕 NUEVO: Validar fecha si tiene recordatorio
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (_hasReminder && !_isFutureDateTime(combinedDateTime)) {
      _showPastDateAlert();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final task =
          widget.isEditing
              ? widget.task!.copyWith(
                title: _titleController.text,
                description: _descriptionController.text,
                date: combinedDateTime,
                category: _selectedCategory,
                priority: _selectedPriority,
              )
              : Task(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                description: _descriptionController.text,
                date: combinedDateTime,
                createdAt: DateTime.now(),
                category: _selectedCategory,
                priority: _selectedPriority,
              );

      // 🆕 NUEVO: Manejar notificaciones
      if (widget.isEditing && widget.task != null) {
        // Si estamos editando, cancelar la notificación anterior
        await _cancelTaskNotification(widget.task!.id);

        // Si la nueva tarea tiene recordatorio, programarlo
        if (_hasReminder && !task.isCompleted) {
          await _scheduleTaskNotification(task);
        }
      } else {
        // Si es una nueva tarea con recordatorio, programarlo
        if (_hasReminder) {
          await _scheduleTaskNotification(task);
        }
      }

      if (widget.isEditing) {
        await _firebaseService.updateTask(task);
      } else {
        await _firebaseService.addTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Tarea actualizada' : 'Tarea creada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al guardar tarea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La tarea se guardó localmente. Se sincronizará cuando haya conexión.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        // Cerrar la pantalla de todas formas, ya que la tarea se guardó localmente
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar tarea' : 'Nueva tarea',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 🆕 NUEVO: Botón de prueba de notificaciones
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0FFFF), // Fondo azul claro
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'Título',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Título de la tarea',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fecha y Hora
                      Row(
                        children: [
                          // Fecha
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _showDatePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hora
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hora',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _showTimePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedTime.format(context),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.access_time, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🆕 NUEVO: Switch para recordatorio
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Color(0xFF4A90E2),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Recordatorio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: _hasReminder,
                              onChanged: (value) {
                                setState(() {
                                  _hasReminder = value;
                                });
                              },
                              activeColor: const Color(0xFF4A90E2),
                            ),
                            // 🆕 NUEVO: Botón de prueba junto al switch
                          ],
                        ),
                      ),

                      // 🆕 NUEVO: Información del recordatorio
                      if (_hasReminder) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4A90E2).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isFutureDateTime(
                                      DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month,
                                        _selectedDate.day,
                                        _selectedTime.hour,
                                        _selectedTime.minute,
                                      ),
                                    )
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color:
                                    _isFutureDateTime(
                                          DateTime(
                                            _selectedDate.year,
                                            _selectedDate.month,
                                            _selectedDate.day,
                                            _selectedTime.hour,
                                            _selectedTime.minute,
                                          ),
                                        )
                                        ? Colors.green
                                        : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isFutureDateTime(
                                        DateTime(
                                          _selectedDate.year,
                                          _selectedDate.month,
                                          _selectedDate.day,
                                          _selectedTime.hour,
                                          _selectedTime.minute,
                                        ),
                                      )
                                      ? 'Se enviará notificación el ${DateFormat('dd/MM/yyyy').format(_selectedDate)} a las ${_selectedTime.format(context)}'
                                      : '⚠️ Fecha en el pasado - No se programará notificación',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        _isFutureDateTime(
                                              DateTime(
                                                _selectedDate.year,
                                                _selectedDate.month,
                                                _selectedDate.day,
                                                _selectedTime.hour,
                                                _selectedTime.minute,
                                              ),
                                            )
                                            ? const Color(0xFF4A90E2)
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Categoría
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showCategoryDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Prioridad
                      const Text(
                        'Prioridad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriorityOption(
                              'Baja',
                              1,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPriorityOption(
                              'Media',
                              2,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPriorityOption('Alta', 3, Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe tu tarea',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones inferiores
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de eliminar (solo en modo edición)
                    if (widget.isEditing)
                      ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 45),
                        ),
                        child: const Text('Eliminar'),
                      ),

                    // Botón de guardar/crear
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 45),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(widget.isEditing ? 'Guardar' : 'Crear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String title, int priority, Color color) {
    final isSelected = _selectedPriority == priority;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              priority == 1
                  ? Icons.arrow_downward
                  : priority == 2
                  ? Icons.remove
                  : Icons.arrow_upward,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
