import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Lista de tareas para el día seleccionado (simulada)
  List<String> _tasks = [];

  // Mapa que simula tareas para diferentes días
  final Map<String, List<String>> _tasksByDate = {
    '2025-08-17': ['Tarea 1', 'Tarea 2', 'Tarea 3', 'Tarea 4', 'Tarea 5'],
    '2025-08-05': ['Reunión importante', 'Llamar al doctor'],
    '2025-08-10': ['Entregar informe', 'Comprar regalo'],
  };

  // Formateadores de fecha
  late DateFormat _monthYearFormat;
  late DateFormat _selectedDayFormat;
  late DateFormat _dayFormat;

  @override
  void initState() {
    super.initState();

    // Configurar los formateadores
    _monthYearFormat = DateFormat('MMMM yyyy', 'es_ES');
    _selectedDayFormat = DateFormat('EEE, MMM d', 'es_ES');
    _dayFormat = DateFormat('dd/MM/yyyy');

    // Establecemos el mes actual a agosto 2025 para coincidir con la imagen
    _currentMonth = DateTime(2025, 8, 1);
    // Establecemos la fecha seleccionada al 17 de agosto de 2025
    _selectedDate = DateTime(2025, 8, 17);
    // Cargamos las tareas para la fecha seleccionada
    _loadTasksForSelectedDate();
  }

  // Carga las tareas para la fecha seleccionada
  void _loadTasksForSelectedDate() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _tasks = _tasksByDate[dateKey] ?? [];
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
  }

  // Cambia al mes siguiente
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  // Muestra el diálogo para agregar una tarea
  void _showAddTaskDialog() {
    // Aquí se implementaría el diálogo para agregar una tarea
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agregar tarea para ${_dayFormat.format(_selectedDate)}'),
        duration: const Duration(seconds: 2),
      ),
    );
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

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% de padding
        child: Column(
          children: [
            // Contenedor del calendario
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFCCF9F9), // Color de fondo del calendario (azul muy claro)
                borderRadius: BorderRadius.circular(fontSize),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto "Select date"
                  Text(
                    'Select date',
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
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
                          onPressed: () {
                            // Aquí iría la lógica para editar la fecha manualmente
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
                        Row(
                          children: [
                            Text(
                              _monthYearFormat.format(_currentMonth),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: fontSize * 1.5),
                          ],
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
                            onPressed: _showAddTaskDialog,
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
                color: const Color(0xFFCCF9F9), // Color de fondo (azul muy claro)
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
                    child: _tasks.isEmpty
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
                                (task) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.01,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        child: Text(
                                          task,
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Botón "Mostrar más"
                              if (_tasks.length > 3)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: screenHeight * 0.01,
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        // Aquí iría la lógica para mostrar más tareas
                                      },
                                      child: Text(
                                        'Mostrar más',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.bold,
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
    );
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
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Encabezados de días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: daysOfWeek
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
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final hasTasks = _tasksByDate.containsKey(dateKey);

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
                      color: isSelected
                          ? const Color(0xFF00CED1) // Color turquesa para el día seleccionado
                          : Colors.transparent,
                      border: hasTasks && !isSelected
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
                        fontWeight: isSelected || isToday
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