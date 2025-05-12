import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import 'task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Fecha seleccionada actualmente
  DateTime _selectedDate = DateTime.now();

  // Mes que se está mostrando actualmente
  DateTime _currentMonth = DateTime.now();

  // Lista de tareas para el día seleccionado
  List<Task> _tasks = [];

  // Fechas que tienen tareas
  List<DateTime> _datesWithTasks = [];

  // Servicio de Firebase
  late FirebaseService _firebaseService;

  bool _isLoading = true;

  // Formateadores de fecha
  late DateFormat _monthYearFormat;
  late DateFormat _selectedDayFormat;
  late DateFormat _dayFormat;

  @override
  void initState() {
    super.initState();

    // Obtener el ID del usuario actual o usar 'guest' si no hay usuario
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);

    // Configurar los formateadores
    _monthYearFormat = DateFormat('MMMM yyyy', 'es_ES');
    _selectedDayFormat = DateFormat('EEE, MMM d', 'es_ES');
    _dayFormat = DateFormat('dd/MM/yyyy');

    // Cargar las tareas para la fecha seleccionada
    _loadTasksForSelectedDate();
    // Cargar las fechas con tareas para el mes actual
    _loadDatesWithTasks();
  }

  // Carga las fechas que tienen tareas para el mes actual
  Future<void> _loadDatesWithTasks() async {
    try {
      final dates = await _firebaseService.getDatesWithTasks(
        _currentMonth.year,
        _currentMonth.month,
      );

      if (mounted) {
        setState(() {
          _datesWithTasks = dates;
        });
      }
    } catch (e) {
      print('Error al cargar fechas con tareas: $e');
    }
  }

  // Carga las tareas para la fecha seleccionada
  void _loadTasksForSelectedDate() {
    setState(() {
      _isLoading = true;
    });

    _firebaseService.getTasksByDate(_selectedDate).listen((tasks) {
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    });
  }

  // Cambia la fecha seleccionada
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadTasksForSelectedDate();
  }

  // Cambia al mes anterior
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadDatesWithTasks();
  }

  // Cambia al mes siguiente
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadDatesWithTasks();
  }

  // Navega a la pantalla de formulario de tareas
  void _navigateToTaskForm({Task? task}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskFormScreen(task: task, isEditing: task != null),
      ),
    );

    if (result == true) {
      // La tarea se guardó correctamente
      _loadTasksForSelectedDate();
      _loadDatesWithTasks();
    }
  }

  // Elimina una tarea
  Future<void> _deleteTask(Task task) async {
    try {
      await _firebaseService.deleteTask(task.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
      _loadTasksForSelectedDate();
      _loadDatesWithTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
      );
    }
  }

  // Marca una tarea como completada o pendiente
  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _firebaseService.toggleTaskCompletion(task.id, !task.isCompleted);
      _loadTasksForSelectedDate();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculamos valores relativos
    final fontSize = screenWidth * 0.04; // 4% del ancho para texto normal
    final smallFontSize = screenWidth * 0.035; // 3.5% para texto pequeño
    final largeFontSize = screenWidth * 0.055; // 5.5% para texto grande

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // 4% de padding
          child: Column(
            children: [
              // Contenedor del calendario
              Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFCCF9F9,
                  ), // Color de fondo del calendario (azul muy claro)
                  borderRadius: BorderRadius.circular(fontSize),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Texto "Select date"
                    Text(
                      'Seleccionar fecha',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),

                    // Fecha seleccionada con botón de edición
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.01,
                        horizontal: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDayFormat.format(_selectedDate),
                            style: TextStyle(
                              fontSize: largeFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: fontSize * 1.2),
                            onPressed: () async {
                              // Mostrar selector de fecha
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );

                              if (pickedDate != null) {
                                _onDateSelected(pickedDate);

                                // Actualizar el mes actual si es necesario
                                if (pickedDate.month != _currentMonth.month ||
                                    pickedDate.year != _currentMonth.year) {
                                  setState(() {
                                    _currentMonth = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      1,
                                    );
                                  });
                                  _loadDatesWithTasks();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Selector de mes con navegación
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dropdown para seleccionar mes/año
                          GestureDetector(
                            onTap: () async {
                              // Mostrar selector de fecha para el mes
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _currentMonth,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDatePickerMode: DatePickerMode.year,
                              );

                              if (pickedDate != null) {
                                setState(() {
                                  _currentMonth = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    1,
                                  );
                                });
                                _loadDatesWithTasks();
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  _monthYearFormat.format(_currentMonth),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: fontSize * 1.5,
                                ),
                              ],
                            ),
                          ),
                          // Botones de navegación
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_left,
                                  size: fontSize * 1.5,
                                ),
                                onPressed: _previousMonth,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  size: fontSize * 1.5,
                                ),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Calendario
                    _buildCalendarGrid(fontSize),

                    // Botón para agregar tarea
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Agregar tarea',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            FloatingActionButton(
                              backgroundColor: const Color(0xFF0047AB),
                              onPressed: () => _navigateToTaskForm(),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Sección de tareas para el día seleccionado
              Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFCCF9F9,
                  ), // Color de fondo (azul muy claro)
                  borderRadius: BorderRadius.circular(fontSize),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Encabezado de tareas
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.04,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A90E2), // Azul
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      width: double.infinity,
                      child: Text(
                        'Tareas para el día (${_dayFormat.format(_selectedDate)})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Lista de tareas
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      constraints: BoxConstraints(
                        minHeight: screenHeight * 0.2,
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _tasks.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.03,
                                  ),
                                  child: Text(
                                    'No hay tareas para este día',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ..._tasks.map(
                                    (task) => Dismissible(
                                      key: Key(task.id),
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        _deleteTask(task);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          bottom: screenHeight * 0.01,
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: GestureDetector(
                                            onTap:
                                                () =>
                                                    _toggleTaskCompletion(task),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    task.isCompleted
                                                        ? _getPriorityColor(
                                                          task.priority,
                                                        )
                                                        : Colors.transparent,
                                                border: Border.all(
                                                  color:
                                                      task.isCompleted
                                                          ? _getPriorityColor(
                                                            task.priority,
                                                          )
                                                          : Colors.grey,
                                                  width: 2,
                                                ),
                                              ),
                                              child:
                                                  task.isCompleted
                                                      ? Icon(
                                                        Icons.check,
                                                        size: fontSize,
                                                        color: Colors.white,
                                                      )
                                                      : const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                            ),
                                          ),
                                          title: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  task.isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                              color:
                                                  task.isCompleted
                                                      ? Colors.grey
                                                      : Colors.black,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (task
                                                  .description
                                                  .isNotEmpty) ...[
                                                Text(
                                                  task.description,
                                                  style: TextStyle(
                                                    fontSize: smallFontSize,
                                                    color: Colors.grey[700],
                                                    decoration:
                                                        task.isCompleted
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: smallFontSize,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat(
                                                      'HH:mm',
                                                    ).format(task.date),
                                                    style: TextStyle(
                                                      fontSize: smallFontSize,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getPriorityColor(
                                                        task.priority,
                                                      ).withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _getPriorityText(
                                                        task.priority,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            smallFontSize * 0.9,
                                                        color:
                                                            _getPriorityColor(
                                                              task.priority,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed:
                                                () => _navigateToTaskForm(
                                                  task: task,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  // Obtener el color según la prioridad
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Obtener el texto según la prioridad
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Baja';
      case 3:
        return 'Alta';
      default:
        return 'Media';
    }
  }

  // Construye la cuadrícula del calendario
  Widget _buildCalendarGrid(double fontSize) {
    // Obtenemos el primer día del mes
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );

    // Obtenemos el último día del mes
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

    // Calculamos el día de la semana del primer día (0 = domingo, 1 = lunes, etc.)
    int firstWeekday = firstDayOfMonth.weekday;
    // Ajustamos para que la semana comience en domingo (0)
    firstWeekday = firstWeekday % 7;

    // Calculamos el número de días en el mes
    final daysInMonth = lastDayOfMonth.day;

    // Calculamos el número de filas necesarias
    final numRows = ((firstWeekday + daysInMonth) / 7).ceil();

    // Días de la semana
    final daysOfWeek = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

    return Column(
      children: [
        // Encabezados de días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              daysOfWeek
                  .map(
                    (day) => SizedBox(
                      width: fontSize * 2,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),

        SizedBox(height: fontSize * 0.8),

        // Cuadrícula de días
        ...List.generate(numRows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: fontSize * 0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (col) {
                final index = row * 7 + col;
                final dayOffset = index - firstWeekday;

                // Si el día está fuera del mes actual, mostramos un espacio vacío
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return SizedBox(width: fontSize * 2);
                }

                // Día actual
                final day = dayOffset + 1;
                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                );

                // Verificamos si este día tiene tareas
                final hasTask = _datesWithTasks.any(
                  (taskDate) =>
                      taskDate.year == date.year &&
                      taskDate.month == date.month &&
                      taskDate.day == date.day,
                );

                // Verificamos si es el día seleccionado
                final isSelected =
                    _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;

                // Verificamos si es el día actual
                final isToday =
                    DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return GestureDetector(
                  onTap: () => _onDateSelected(date),
                  child: Container(
                    width: fontSize * 2.5,
                    height: fontSize * 2.5,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(
                                0xFF00CED1,
                              ) // Color turquesa para el día seleccionado
                              : Colors.transparent,
                      border:
                          hasTask && !isSelected
                              ? Border.all(
                                color: const Color(0xFF00CED1),
                                width: 1,
                              )
                              : null,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: fontSize * 0.9,
                        fontWeight:
                            isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
