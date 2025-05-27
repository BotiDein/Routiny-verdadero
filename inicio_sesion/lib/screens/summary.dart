import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class ResumenPersonalScreen extends StatefulWidget {
  const ResumenPersonalScreen({super.key});

  @override
  State<ResumenPersonalScreen> createState() => _ResumenPersonalScreenState();
}

class _ResumenPersonalScreenState extends State<ResumenPersonalScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late FirebaseService _firebaseService;
  bool _isLoading = true;

  // Datos para el resumen
  DateTime _selectedMonth = DateTime.now();

  // Datos de tareas
  List<Task> _monthTasks = [];
  int _totalTasks = 0;
  int _completedTasks = 0;

  // Datos de hábitos
  List<Habit> _monthHabits = [];
  int _totalHabits = 0;
  int _completedHabits = 0;

  // Rachas
  int _currentStreak = 0;
  int _longestStreak = 0;

  // Tiempo por categoría - CORREGIDO: Solo contar tareas/hábitos completados
  Map<String, double> _timeSpent = {};

  // Actividad diaria
  Map<int, int> _activityByDay = {};
  Map<int, int> _tasksByDay = {};
  Map<int, int> _habitsByDay = {};
  final List<FlSpot> _activitySpots = [];

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firstDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );

      // Cargar tareas del mes desde Firebase
      final tasks = await _firebaseService.getTasksForDateRange(
        firstDayOfMonth,
        lastDayOfMonth,
      );
      _monthTasks = tasks;

      // Intentar cargar hábitos desde Firebase primero
      try {
        final habits = await _firebaseService.getHabitsFuture();
        _monthHabits =
            habits.where((habit) {
              return habit.createdAt.isBefore(
                lastDayOfMonth.add(const Duration(days: 1)),
              );
            }).toList();
      } catch (e) {
        print('Error al cargar hábitos desde Firebase: $e');
        final habits = await _storageService.getHabits();
        _monthHabits =
            habits.where((habit) {
              return habit.createdAt.isBefore(
                lastDayOfMonth.add(const Duration(days: 1)),
              );
            }).toList();
      }

      // Calcular estadísticas
      _calculateStatistics(firstDayOfMonth, lastDayOfMonth);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del mes: $e');
      _loadDemoData();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadDemoData() {
    _totalTasks = 0;
    _completedTasks = 0;
    _totalHabits = 0;
    _completedHabits = 0;
    _currentStreak = 0;
    _longestStreak = 0;

    _timeSpent = {};

    _activityByDay = {};
    _tasksByDay = {};
    _habitsByDay = {};
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      _activityByDay[i] = 0;
      _tasksByDay[i] = 0;
      _habitsByDay[i] = 0;
    }
  }

  // 🔧 CORREGIDO: Método de cálculo de estadísticas mejorado
  void _calculateStatistics(DateTime startDate, DateTime endDate) {
    // Reiniciar contadores
    _totalTasks = _monthTasks.length;
    _completedTasks = _monthTasks.where((task) => task.isCompleted).length;

    _totalHabits = _monthHabits.length;
    _completedHabits = 0;

    // Reiniciar tiempo por categoría
    _timeSpent = {};

    // Reiniciar actividad diaria
    _activityByDay = {};
    _tasksByDay = {};
    _habitsByDay = {};
    final daysInMonth = endDate.day;
    for (int i = 1; i <= daysInMonth; i++) {
      _activityByDay[i] = 0;
      _tasksByDay[i] = 0;
      _habitsByDay[i] = 0;
    }

    // 🔧 CORREGIDO: Procesar tareas - SOLO las completadas cuentan para tiempo por categoría
    for (var task in _monthTasks) {
      // Contar actividad por día
      if (task.isCompleted) {
        final day = task.date.day;
        _activityByDay[day] = (_activityByDay[day] ?? 0) + 1;
        _tasksByDay[day] = (_tasksByDay[day] ?? 0) + 1;

        // 🔧 CORREGIDO: Solo las tareas COMPLETADAS contribuyen al tiempo por categoría
        final category = task.category;
        // Cada tarea completada representa 1 punto de actividad (no horas)
        _timeSpent[category] = (_timeSpent[category] ?? 0) + 1.0;
      }
    }

    // 🔧 CORREGIDO: Procesar hábitos mejorado
    for (var habit in _monthHabits) {
      final category = habit.category;
      final type = habit.type;

      // Verificar si el hábito está completado
      bool isCompleted = false;
      double activityPoints = 0.0;

      if (type == 'boolean') {
        // Contar días completados en el mes actual
        int completedDaysCount = 0;

        habit.completedDates.forEach((dateStr, status) {
          try {
            final date = DateTime.parse(dateStr);
            if (date.year == _selectedMonth.year &&
                date.month == _selectedMonth.month &&
                status == 2) {
              // Solo estado completado (2)
              completedDaysCount++;
            }
          } catch (e) {
            print('Error al parsear fecha para hábito boolean: $e');
          }
        });

        // Si hay días completados, el hábito cuenta como activo
        if (completedDaysCount > 0) {
          isCompleted = true;
          activityPoints =
              completedDaysCount.toDouble(); // 1 punto por día completado
        }
      } else if (type == 'count') {
        final current = habit.current is int ? habit.current as int : 0;
        final goal = habit.goal is int ? habit.goal as int : 0;
        if (goal > 0 && current >= goal) {
          isCompleted = true;
          activityPoints = 1.0; // 1 punto por hábito de conteo completado
        }
      } else if (type == 'time') {
        // Calcular tiempo total registrado en el mes
        double totalHours = 0.0;

        if (habit.registeredTimes.isNotEmpty) {
          habit.registeredTimes.forEach((dateStr, timeStr) {
            try {
              final date = DateTime.parse(dateStr);
              if (date.year == _selectedMonth.year &&
                  date.month == _selectedMonth.month) {
                totalHours += _convertTimeStringToHours(timeStr);
              }
            } catch (e) {
              print('Error al procesar tiempo registrado: $e');
            }
          });
        }

        if (totalHours > 0) {
          isCompleted = true;
          // Para hábitos de tiempo, usar las horas reales registradas
          activityPoints = totalHours;
        }
      }

      if (isCompleted) {
        _completedHabits++;
        // Solo agregar puntos de actividad si el hábito está completado
        _timeSpent[category] = (_timeSpent[category] ?? 0) + activityPoints;
      }

      // Contar actividad por día para hábitos usando fechas específicas
      if (habit.completedDates.isNotEmpty) {
        habit.completedDates.forEach((dateStr, status) {
          try {
            final date = DateTime.parse(dateStr);
            if (date.year == _selectedMonth.year &&
                date.month == _selectedMonth.month &&
                status > 0) {
              // Cualquier progreso cuenta para actividad diaria
              final day = date.day;
              _activityByDay[day] = (_activityByDay[day] ?? 0) + 1;
              _habitsByDay[day] = (_habitsByDay[day] ?? 0) + 1;
            }
          } catch (e) {
            print('Error al procesar fecha de hábito: $e');
          }
        });
      }
    }

    // Calcular rachas
    _calculateStreaks();
  }

  void _calculateStreaks() {
    Map<String, bool> activityByDate = {};
    final today = DateTime.now();

    // Marcar días con tareas completadas (solo hasta hoy)
    for (var task in _monthTasks) {
      if (task.isCompleted && !task.date.isAfter(today)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(task.date);
        activityByDate[dateStr] = true;
      }
    }

    // Marcar días con hábitos completados (solo hasta hoy)
    for (var habit in _monthHabits) {
      habit.completedDates.forEach((dateStr, status) {
        if (status == 2) {
          final date = DateTime.parse(dateStr);
          if (!date.isAfter(today)) {
            activityByDate[dateStr] = true;
          }
        }
      });
    }

    // Calcular racha actual
    int currentStreak = 0;
    DateTime checkDate = today;

    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      if (activityByDate[dateStr] == true) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Calcular racha más larga
    int longestStreak = 0;
    int tempStreak = 0;

    List<DateTime> dates =
        activityByDate.keys
            .map((dateStr) => DateFormat('yyyy-MM-dd').parse(dateStr))
            .where((date) => !date.isAfter(today))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    for (int i = 0; i < dates.length; i++) {
      if (i > 0) {
        final difference = dates[i].difference(dates[i - 1]).inDays;
        if (difference == 1) {
          tempStreak++;
        } else {
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
          tempStreak = 1;
        }
      } else {
        tempStreak = 1;
      }
    }

    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _prepareActivityChart() {
    // Método mantenido por compatibilidad
  }

  int _compareTimeStrings(String time1, String time2) {
    final minutes1 = _convertTimeStringToMinutes(time1);
    final minutes2 = _convertTimeStringToMinutes(time2);
    return minutes1.compareTo(minutes2);
  }

  int _convertTimeStringToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return hours * 60 + minutes + (seconds > 0 ? 1 : 0);
      }
    } catch (e) {
      print('Error al convertir tiempo: $e');
    }
    return 0;
  }

  double _convertTimeStringToHours(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 3) {
        final hours = double.tryParse(parts[0]) ?? 0;
        final minutes = double.tryParse(parts[1]) ?? 0;
        final seconds = double.tryParse(parts[2]) ?? 0;
        return hours + (minutes / 60) + (seconds / 3600);
      }
    } catch (e) {
      print('Error al convertir tiempo: $e');
    }
    return 0.0;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
    _loadMonthData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
    _loadMonthData();
  }

  void _showRachaInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Cómo funcionan las rachas?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Las rachas miden tu consistencia diaria:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Cada día que completes al menos una tarea o hábito, tu racha aumenta en 1.',
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Si un día no completas ninguna actividad, tu racha actual se reinicia a 0.',
                ),
                const SizedBox(height: 8),
                const Text(
                  '• La racha más larga muestra tu mejor secuencia de días consecutivos con actividades completadas.',
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Solo se cuentan actividades hasta el día actual, no se consideran actividades futuras.',
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Mantén tu racha activa para desarrollar consistencia en tus hábitos!',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resumen Personal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFE0FFFF),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Selector de mes
                    _buildMonthSelector(),

                    const SizedBox(height: 24),

                    // Círculo de porcentaje
                    _buildCompletionCircle(),

                    const SizedBox(height: 32),

                    // Rachas
                    _buildStreakSection(),

                    const SizedBox(height: 32),

                    // 🔧 CORREGIDO: Título actualizado para reflejar el cambio
                    _buildTimeSpentBarChart(),

                    const SizedBox(height: 32),

                    // Gráfico de actividad diaria mejorado
                    _buildActivityChart(),

                    const SizedBox(height: 32),

                    // Estadísticas
                    _buildStatisticsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCircle() {
    final totalActivities = _totalTasks + _totalHabits;
    final completedActivities = _completedTasks + _completedHabits;

    final completionPercentage =
        totalActivities > 0
            ? (completedActivities / totalActivities * 100).round()
            : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Progreso General',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: CircleProgressPainter(
                    percentage:
                        totalActivities > 0
                            ? completedActivities / totalActivities
                            : 0,
                    color: const Color(0xFF0052A9),
                    strokeWidth: 20,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$completionPercentage%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'De metas\ncumplidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressDetail(
                'Tareas',
                _completedTasks,
                _totalTasks,
                Colors.blue,
              ),
              const SizedBox(width: 24),
              _buildProgressDetail(
                'Hábitos',
                _completedHabits,
                _totalHabits,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetail(
    String label,
    int completed,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('($percentage%)', style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildStreakSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB3FFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tus rachas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showRachaInfoDialog,
                tooltip: '¿Cómo funcionan las rachas?',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem(
                'Racha actual',
                _currentStreak,
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStreakItem(
                'Racha más larga',
                _longestStreak,
                Icons.emoji_events,
                Colors.amber[800]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 48),
        const SizedBox(height: 12),
        Text(
          '$value días',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  // 🔧 CORREGIDO: Título y descripción actualizados
  Widget _buildTimeSpentBarChart() {
    final sortedCategories = _timeSpent.keys.toList();

    if (sortedCategories.isNotEmpty) {
      sortedCategories.sort((a, b) => _timeSpent[b]!.compareTo(_timeSpent[a]!));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividades Completadas por Categoría',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Solo se muestran categorías con actividades completadas',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _timeSpent.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'No hay actividades completadas para mostrar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
              : Column(
                children:
                    sortedCategories.take(6).map((category) {
                      final value = _timeSpent[category]!;
                      final maxValue = _timeSpent.values.reduce(
                        (a, b) => a > b ? a : b,
                      );

                      final percentage = maxValue > 0 ? value / maxValue : 0.0;
                      final color = _getCategoryColor(category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      if (percentage > 0)
                                        FractionallySizedBox(
                                          widthFactor: percentage.clamp(
                                            0.01,
                                            1.0,
                                          ),
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    value % 1 == 0
                                        ? value.toInt().toString()
                                        : value.toStringAsFixed(1),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final Map<String, Color> categoryColors = {
      'Trabajo': Colors.blue,
      'Estudio': Colors.purple,
      'Ejercicio': Colors.green,
      'Hobbies': Colors.orange,
      'Lectura': Colors.teal,
      'Otros': Colors.blueGrey,
      'Personal': Colors.pink,
      'Salud': Colors.red,
      'Finanzas': Colors.amber,
      'Música': Colors.deepOrange,
      'Deportes': Colors.lightBlue,
      'Arte': Colors.indigo,
      'General': Colors.grey,
      'Educación': Colors.purple,
    };

    return categoryColors[category] ?? Colors.grey;
  }

  Widget _buildActivityChart() {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad diaria',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Número de actividades completadas por día',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child:
                _activityByDay.isEmpty
                    ? const Center(child: Text('No hay datos para mostrar'))
                    : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            (_activityByDay.values.isEmpty
                                ? 0
                                : _activityByDay.values.reduce(
                                  (a, b) => a > b ? a : b,
                                )) +
                            1,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final day = group.x.toInt();
                              final total = _activityByDay[day] ?? 0;
                              final tasks = _tasksByDay[day] ?? 0;
                              final habits = _habitsByDay[day] ?? 0;

                              return BarTooltipItem(
                                'Día $day\nTotal: $total\nTareas: $tasks\nHábitos: $habits',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value % 5 == 0 ||
                                    value == 1 ||
                                    value == daysInMonth) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
                                if (value % 1 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _getBarGroups(),
                      ),
                    ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Tareas', Colors.blue),
              const SizedBox(width: 20),
              _buildLegendItem('Hábitos', Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Días del mes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    List<BarChartGroupData> barGroups = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final tasks = _tasksByDay[day] ?? 0;
      final habits = _habitsByDay[day] ?? 0;

      if (tasks > 0 || habits > 0) {
        barGroups.add(
          BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: tasks.toDouble(),
                color: Colors.blue,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: habits.toDouble(),
                color: Colors.green,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      } else {
        barGroups.add(
          BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: 0,
                color: Colors.grey.withOpacity(0.2),
                width: 8,
              ),
            ],
          ),
        );
      }
    }

    return barGroups;
  }

  Widget _buildStatisticsSection() {
    final activeCategories = _timeSpent.keys.length;
    final totalActivities = _totalTasks + _totalHabits;
    final completedActivities = _completedTasks + _completedHabits;
    final productivity =
        totalActivities > 0
            ? (completedActivities / totalActivities * 100).round()
            : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB3FFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _estadisticaItem(
            Icons.task_alt,
            Colors.green,
            'Tareas completadas',
            '$_completedTasks de $_totalTasks',
          ),
          _estadisticaItem(
            Icons.trending_up,
            Colors.blue,
            'Hábitos activos',
            '$_completedHabits de $_totalHabits',
          ),
          _estadisticaItem(
            Icons.category,
            Colors.purple,
            'Categorías activas',
            '$activeCategories',
          ),
          _estadisticaItem(
            Icons.auto_graph,
            Colors.orange,
            'Productividad general',
            '$productivity%',
          ),
        ],
      ),
    );
  }

  Widget _estadisticaItem(
    IconData icon,
    Color color,
    String label,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(valor, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// Pintor personalizado para el círculo de progreso
class CircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  CircleProgressPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Dibujar círculo de fondo
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Dibujar arco de progreso
    final progressPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
