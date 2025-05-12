import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/hobby.dart';
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
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, double> _timeSpent = {};
  Map<int, int> _activityByDay = {};
  
  // Datos para el gráfico de actividad diaria
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
      // Obtener datos del mes seleccionado
      final data = await _firebaseService.getMonthlyData(
        _selectedMonth.year, 
        _selectedMonth.month
      );
      
      setState(() {
        _totalTasks = data['totalTasks'] ?? 0;
        _completedTasks = data['completedTasks'] ?? 0;
        _currentStreak = data['currentStreak'] ?? 0;
        _longestStreak = data['longestStreak'] ?? 0;
        _timeSpent = Map<String, double>.from(data['timeByCategory'] ?? {});
        _activityByDay = Map<int, int>.from(data['activityByDay'] ?? {});
        
        // Preparar datos para el gráfico de actividad
        _prepareActivityChart();
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del mes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _prepareActivityChart() {
    _activitySpots = _activityByDay.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();
    
    // Ordenar por día
    _activitySpots.sort((a, b) => a.x.compareTo(b.x));
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Escalado responsivo
    double scaleWidth(double value) => value * screenWidth / 720;
    double scaleHeight(double value) => value * screenHeight / 1280;
    double scaleFont(double value) => value * screenWidth / 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resumen Personal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: scaleFont(30),
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
              padding: EdgeInsets.all(scaleWidth(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: scaleHeight(16)),
                  
                  // Selector de mes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth),
                        style: TextStyle(
                          fontSize: scaleFont(26),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: scaleHeight(16)),

                  // Círculo de porcentaje
                  _buildCompletionCircle(scaleWidth, scaleFont),

                  SizedBox(height: scaleHeight(30)),

                  // Rachas
                  _buildStreakSection(scaleWidth, scaleHeight, scaleFont),
                  
                  SizedBox(height: scaleHeight(30)),

                  // Gráfico de actividad diaria
                  _buildActivityChart(scaleWidth, scaleHeight, scaleFont),
                  
                  SizedBox(height: scaleHeight(30)),

                  // Tiempo dedicado
                  _buildTimeSpentSection(scaleWidth, scaleHeight, scaleFont),

                  SizedBox(height: scaleHeight(30)),

                  // Estadísticas
                  _buildStatisticsSection(scaleWidth, scaleHeight, scaleFont),
                  
                  SizedBox(height: scaleHeight(30)),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCompletionCircle(double Function(double) scaleWidth, double Function(double) scaleFont) {
    final completionPercentage = _totalTasks > 0 
        ? (_completedTasks / _totalTasks * 100).round() 
        : 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: scaleWidth(250),
          height: scaleWidth(250),
          child: CustomPaint(
            painter: CircleProgressPainter(
              percentage: _totalTasks > 0 ? _completedTasks / _totalTasks : 0,
              color: const Color(0xFF0052A9),
              strokeWidth: scaleWidth(18),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$completionPercentage%',
              style: TextStyle(
                fontSize: scaleFont(48),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'De metas\ncumplidas',
              style: TextStyle(
                fontSize: scaleFont(20),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStreakSection(
    double Function(double) scaleWidth, 
    double Function(double) scaleHeight, 
    double Function(double) scaleFont
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scaleWidth(20)),
      decoration: BoxDecoration(
        color: const Color(0xFFB3FFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0052A9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus rachas',
            style: TextStyle(
              fontSize: scaleFont(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: scaleHeight(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem(
                'Racha actual',
                _currentStreak,
                Icons.local_fire_department,
                Colors.orange,
                scaleFont,
              ),
              _buildStreakItem(
                'Racha más larga',
                _longestStreak,
                Icons.emoji_events,
                Colors.amber[800]!,
                scaleFont,
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
    double Function(double) scaleFont
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: scaleFont(40)),
        SizedBox(height: 8),
        Text(
          '$value días',
          style: TextStyle(
            fontSize: scaleFont(24),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: scaleFont(16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityChart(
    double Function(double) scaleWidth, 
    double Function(double) scaleHeight, 
    double Function(double) scaleFont
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scaleWidth(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0052A9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad diaria',
            style: TextStyle(
              fontSize: scaleFont(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: scaleHeight(10)),
          Container(
            height: scaleHeight(200),
            child: _activitySpots.isEmpty
                ? Center(child: Text('No hay datos para mostrar'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
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
                            getTitlesWidget: (value, meta) {
                              // Mostrar solo algunos días para no sobrecargar
                              if (value % 5 == 0 || value == 1) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: scaleFont(12),
                                    fontWeight: FontWeight.bold,
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
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF4A90E2).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSpentSection(
    double Function(double) scaleWidth, 
    double Function(double) scaleHeight, 
    double Function(double) scaleFont
  ) {
    // Colores para las categorías
    final Map<String, Color> categoryColors = {
      'General': Colors.blue.shade900,
      'Trabajo': Colors.lightBlue,
      'Personal': Colors.cyanAccent,
      'Salud': Colors.green,
      'Educación': Colors.purple,
      'Finanzas': Colors.amber,
      'Música': Colors.deepOrange,
      'Deportes': Colors.teal,
      'Arte': Colors.pink,
      'Lectura': Colors.indigo,
      'Cocina': Colors.brown,
      'Viajes': Colors.lime,
      'Tecnología': Colors.blueGrey,
      'Ejercicio': Colors.red,
    };
    
    // Ordenar categorías por tiempo dedicado
    final sortedCategories = _timeSpent.keys.toList()
      ..sort((a, b) => _timeSpent[b]!.compareTo(_timeSpent[a]!));
    
    // Encontrar el valor máximo para escalar las barras
    final maxValue = _timeSpent.values.isEmpty 
        ? 1.0 
        : _timeSpent.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiempo dedicado',
          style: TextStyle(
            fontSize: scaleFont(24),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: scaleHeight(10)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(scaleWidth(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0052A9), width: 1),
          ),
          child: _timeSpent.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: scaleHeight(30)),
                    child: Text(
                      'No hay datos para mostrar',
                      style: TextStyle(fontSize: scaleFont(16)),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: sortedCategories.take(4).map((category) {
                    final value = _timeSpent[category]!;
                    final factor = value / maxValue;
                    final color = categoryColors[category] ?? Colors.blue;
                    
                    return _barraActividad(
                      category, 
                      factor, 
                      color, 
                      screenHeight: scaleHeight(150),
                      value: value.toStringAsFixed(1),
                      scaleFont: scaleFont,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
  
  Widget _buildStatisticsSection(
    double Function(double) scaleWidth, 
    double Function(double) scaleHeight, 
    double Function(double) scaleFont
  ) {
    // Calcular categorías activas
    final activeCategories = _timeSpent.keys.length;
    
    // Calcular productividad
    final productivity = _totalTasks > 0 
        ? (_completedTasks / _totalTasks * 100).round() 
        : 0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scaleWidth(20)),
      decoration: BoxDecoration(
        color: const Color(0xFFB3FFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0052A9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: scaleFont(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: scaleHeight(10)),
          _estadisticaItem(
            Icons.task_alt, 
            Colors.green, 
            'Tareas completadas', 
            '$_completedTasks de $_totalTasks', 
            scaleFont
          ),
          _estadisticaItem(
            Icons.category, 
            Colors.purple, 
            'Categorías activas', 
            '$activeCategories', 
            scaleFont
          ),
          _estadisticaItem(
            Icons.trending_up, 
            Colors.blue, 
            'Productividad', 
            '$productivity%', 
            scaleFont
          ),
        ],
      ),
    );
  }

  Widget _barraActividad(
    String label, 
    double factor, 
    Color color, 
    {required double screenHeight, 
    required String value,
    required double Function(double) scaleFont}
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: scaleFont(16),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 30,
          height: screenHeight * factor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: scaleFont(14),
          ),
        ),
      ],
    );
  }

  Widget _estadisticaItem(
    IconData icon, 
    Color color, 
    String label, 
    String valor, 
    double Function(double) scaleFont
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: scaleFont(24)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: scaleFont(18), fontWeight: FontWeight.bold),
          ),
          Text(
            valor,
            style: TextStyle(fontSize: scaleFont(18)),
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
