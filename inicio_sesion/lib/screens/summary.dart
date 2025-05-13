import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class ResumenPersonalScreen extends StatefulWidget {
  const ResumenPersonalScreen({super.key});

  @override
  State<ResumenPersonalScreen> createState() => _ResumenPersonalScreenState();
}

class _ResumenPersonalScreenState extends State<ResumenPersonalScreen> {
  late FirebaseService _firebaseService;
  bool _isLoading = true;
  
  // Datos para el resumen
  DateTime _selectedMonth = DateTime.now();
  
  // Datos de tareas
  List<Task> _monthTasks = [];
  int _totalTasks = 0;
  int _completedTasks = 0;
  
  // Datos de hábitos
  List<Map<String, dynamic>> _monthHabits = [];
  int _totalHabits = 0;
  int _completedHabits = 0;
  
  // Rachas
  int _currentStreak = 0;
  int _longestStreak = 0;
  
  // Tiempo por categoría
  Map<String, double> _timeSpent = {};
  
  // Actividad diaria
  Map<int, int> _activityByDay = {};
  List<FlSpot> _activitySpots = [];
  
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
      // Obtener el primer y último día del mes seleccionado
      final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      
      // Cargar tareas del mes
      final tasks = await _firebaseService.getTasksForDateRange(firstDayOfMonth, lastDayOfMonth);
      _monthTasks = tasks;
      
      // Cargar hábitos
      final habits = await _firebaseService.getHabits();
      _monthHabits = habits.map((habit) => habit).toList();
      
      // Calcular estadísticas
      _calculateStatistics(firstDayOfMonth, lastDayOfMonth);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del mes: $e');
      
      // Si hay un error, cargar datos de ejemplo para demostración
      _loadDemoData();
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _loadDemoData() {
    // Datos de ejemplo para demostración en caso de error
    _totalTasks = 25;
    _completedTasks = 18;
    _totalHabits = 8;
    _completedHabits = 5;
    _currentStreak = 4;
    _longestStreak = 7;
    
    _timeSpent = {
      'Trabajo': 12.5,
      'Estudio': 8.2,
      'Ejercicio': 5.0,
      'Hobbies': 7.3,
      'Lectura': 3.8,
      'Otros': 2.1,
    };
    
    // Generar datos de actividad diaria de ejemplo
    _activityByDay = {};
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      _activityByDay[i] = math.Random().nextInt(5); // 0-4 actividades por día
    }
    
    // Preparar datos para el gráfico de actividad
    _prepareActivityChart();
  }
  
  void _calculateStatistics(DateTime startDate, DateTime endDate) {
    // Reiniciar contadores
    _totalTasks = _monthTasks.length;
    _completedTasks = _monthTasks.where((task) => task.isCompleted).length;
    
    // Contar hábitos
    _totalHabits = _monthHabits.length;
    _completedHabits = 0;
    
    // Reiniciar tiempo por categoría
    _timeSpent = {};
    
    // Reiniciar actividad diaria
    _activityByDay = {};
    final daysInMonth = endDate.day;
    for (int i = 1; i <= daysInMonth; i++) {
      _activityByDay[i] = 0;
    }
    
    // Procesar tareas
    for (var task in _monthTasks) {
      // Contar actividad por día
      if (task.isCompleted) {
        final day = task.date.day;
        _activityByDay[day] = (_activityByDay[day] ?? 0) + 1;
      }
      
      // Calcular tiempo por categoría (estimado)
      final category = task.category;
      // Asumimos que cada tarea completada representa 1 hora, y cada tarea pendiente 0.5 horas
      final timeValue = task.isCompleted ? 1.0 : 0.5;
      _timeSpent[category] = (_timeSpent[category] ?? 0) + timeValue;
    }
    
    // Procesar hábitos
    for (var habit in _monthHabits) {
      final category = habit['category'] as String? ?? 'General';
      final type = habit['type'] as String? ?? 'count';
      
      // Verificar si el hábito está completado
      bool isCompleted = false;
      
      if (type == 'boolean') {
        isCompleted = habit['current'] == true;
      } else if (type == 'count') {
        final current = habit['current'] as int? ?? 0;
        final goal = habit['goal'] as int? ?? 0;
        isCompleted = goal > 0 && current >= goal;
      } else if (type == 'time') {
        final current = habit['current'] as String? ?? '00:00:00';
        final goal = habit['goal'] as String? ?? '00:00:00';
        isCompleted = _compareTimeStrings(current, goal) >= 0;
      }
      
      if (isCompleted) {
        _completedHabits++;
      }
      
      // Calcular tiempo por categoría para hábitos (estimado)
      double timeValue = 0.0;
      
      if (type == 'boolean') {
        timeValue = isCompleted ? 1.0 : 0.0;
      } else if (type == 'count') {
        final current = habit['current'] as int? ?? 0;
        final goal = habit['goal'] as int? ?? 0;
        timeValue = goal > 0 ? (current / goal).clamp(0.0, 1.0) * 2.0 : 0.0; // Máximo 2 horas
      } else if (type == 'time') {
        final current = habit['current'] as String? ?? '00:00:00';
        timeValue = _convertTimeStringToHours(current);
      }
      
      _timeSpent[category] = (_timeSpent[category] ?? 0) + timeValue;
      
      // Contar actividad por día para hábitos
      final days = habit['days'] as List<dynamic>? ?? [0, 0, 0, 0, 0, 0, 0];
      
      // Recorrer el mes y verificar los días con actividad
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final weekday = date.weekday % 7; // 0-6 (0 = domingo)
        
        if (days.length > weekday && days[weekday] > 0) {
          _activityByDay[day] = (_activityByDay[day] ?? 0) + 1;
        }
      }
    }
    
    // Calcular rachas
    _calculateStreaks();
    
    // Preparar datos para el gráfico de actividad
    _prepareActivityChart();
  }
  
  void _calculateStreaks() {
    // Crear un mapa de actividad por fecha
    Map<String, bool> activityByDate = {};
    
    // Marcar días con tareas completadas
    for (var task in _monthTasks) {
      if (task.isCompleted) {
        final dateStr = DateFormat('yyyy-MM-dd').format(task.date);
        activityByDate[dateStr] = true;
      }
    }
    
    // Marcar días con hábitos completados
    for (var habit in _monthHabits) {
      final days = habit['days'] as List<dynamic>? ?? [0, 0, 0, 0, 0, 0, 0];
      
      // Recorrer el mes actual
      final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final weekday = date.weekday % 7; // 0-6 (0 = domingo)
        
        if (days.length > weekday && days[weekday] == 2) { // 2 = completado
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          activityByDate[dateStr] = true;
        }
      }
    }
    
    // Calcular racha actual
    int currentStreak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = today;
    
    // Retroceder hasta encontrar un día sin actividad
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
    
    // Ordenar fechas
    List<DateTime> dates = activityByDate.keys
        .map((dateStr) => DateFormat('yyyy-MM-dd').parse(dateStr))
        .toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (int i = 0; i < dates.length; i++) {
      if (i > 0) {
        final difference = dates[i].difference(dates[i - 1]).inDays;
        if (difference == 1) {
          // Días consecutivos
          tempStreak++;
        } else {
          // Reiniciar racha
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
          tempStreak = 1;
        }
      } else {
        tempStreak = 1;
      }
    }
    
    // Verificar la última racha
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }
    
    _currentStreak = currentStreak;
    _longestStreak = longestStreak;
  }
  
  void _prepareActivityChart() {
    _activitySpots = _activityByDay.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();
    
    // Ordenar por día
    _activitySpots.sort((a, b) => a.x.compareTo(b.x));
  }
  
  // Función para comparar dos strings de tiempo (formato HH:MM:SS)
  int _compareTimeStrings(String time1, String time2) {
    final minutes1 = _convertTimeStringToMinutes(time1);
    final minutes2 = _convertTimeStringToMinutes(time2);
    return minutes1.compareTo(minutes2);
  }
  
  // Función para convertir string de tiempo a minutos
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
  
  // Función para convertir string de tiempo a horas (para gráficos)
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
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _loadMonthData();
  }
  
  void _nextMonth() {
    // No permitir seleccionar meses futuros
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return;
    }
    
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
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
                const Text('• Cada día que completes al menos una tarea o hábito, tu racha aumenta en 1.'),
                const SizedBox(height: 8),
                const Text('• Si un día no completas ninguna actividad, tu racha actual se reinicia a 0.'),
                const SizedBox(height: 8),
                const Text('• La racha más larga muestra tu mejor secuencia de días consecutivos con actividades completadas.'),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFE0FFFF),
      body: _isLoading
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

                  // Tiempo dedicado (ahora como gráfico de barras horizontal)
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
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
    // Calcular el total de actividades (tareas + hábitos)
    final totalActivities = _totalTasks + _totalHabits;
    final completedActivities = _completedTasks + _completedHabits;
    
    final completionPercentage = totalActivities > 0 
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                    percentage: totalActivities > 0 ? completedActivities / totalActivities : 0,
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
              _buildProgressDetail('Tareas', _completedTasks, _totalTasks, Colors.blue),
              const SizedBox(width: 24),
              _buildProgressDetail('Hábitos', _completedHabits, _totalHabits, Colors.green),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressDetail(String label, int completed, int total, Color color) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
        Text(
          '($percentage%)',
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
  
  Widget _buildStreakItem(
    String label, 
    int value, 
    IconData icon, 
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 48),
        const SizedBox(height: 12),
        Text(
          '$value días',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeSpentBarChart() {
    // Ordenar categorías por tiempo dedicado
    final sortedCategories = _timeSpent.keys.toList()
      ..sort((a, b) => _timeSpent[b]!.compareTo(_timeSpent[a]!));
    
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
            'Tiempo dedicado (horas)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _timeSpent.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No hay datos para mostrar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : Column(
                  children: sortedCategories.take(6).map((category) {
                    final value = _timeSpent[category]!;
                    final maxValue = _timeSpent.values.reduce((a, b) => a > b ? a : b);
                    final percentage = value / maxValue;
                    
                    // Asignar colores basados en la categoría
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  value.toStringAsFixed(1),
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
    };
    
    return categoryColors[category] ?? Colors.grey;
  }
  
  Widget _buildActivityChart() {
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Número de actividades completadas por día',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: _activitySpots.isEmpty
                ? const Center(child: Text('No hay datos para mostrar'))
                : LineChart(
                    LineChartData(
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
                      titlesData: FlTitlesData(
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
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              // Mostrar solo algunos días para no sobrecargar
                              if (value % 5 == 0 || value == 1 || value == DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day) {
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
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _activitySpots,
                          isCurved: true,
                          color: const Color(0xFF4A90E2),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF4A90E2),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF4A90E2).withOpacity(0.2),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
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
  
  Widget _buildStatisticsSection() {
    // Calcular categorías activas
    final activeCategories = _timeSpent.keys.length;
    
    // Calcular productividad general
    final totalActivities = _totalTasks + _totalHabits;
    final completedActivities = _completedTasks + _completedHabits;
    final productivity = totalActivities > 0 
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
          Text(
            valor,
            style: const TextStyle(fontSize: 18),
          ),
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
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Dibujar arco de progreso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * percentage;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Comenzar desde arriba
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
