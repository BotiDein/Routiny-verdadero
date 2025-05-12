import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'summary.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _todayTasks = [];
  List<Task> _tomorrowTasks = [];
  bool _isLoadingToday = true;
  bool _isLoadingTomorrow = true;
  late FirebaseService _firebaseService;
  late DateTime _tomorrow;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);

    final now = DateTime.now();
    _tomorrow = DateTime(now.year, now.month, now.day + 1);

    _loadTasks();
  }

  // Carga las tareas tanto para hoy como para mañana
  void _loadTasks() {
    _loadTodayTasks();
    _loadTomorrowTasks();
  }

  // Obtiene y escucha las tareas del día actual desde Firebase
  void _loadTodayTasks() {
    if (!mounted) return;

    setState(() {
      _isLoadingToday = true;
    });

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    _firebaseService.getTasksByDate(today).listen(
      (tasks) {
        if (mounted) {
          setState(() {
            _todayTasks = tasks;
            _isLoadingToday = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isLoadingToday = false;
          });
        }
      },
    );
  }

  // Obtiene y escucha las tareas del día siguiente desde Firebase
  void _loadTomorrowTasks() {
    if (!mounted) return;

    setState(() {
      _isLoadingTomorrow = true;
    });

    _firebaseService.getTasksByDate(_tomorrow).listen(
      (tasks) {
        if (mounted) {
          setState(() {
            _tomorrowTasks = tasks;
            _isLoadingTomorrow = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isLoadingTomorrow = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleWidth(double value) => value * screenWidth / 720;
    double scaleHeight(double value) => value * screenHeight / 1280;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
      child: Center(
        child: Column(
          children: [
            SizedBox(height: scaleHeight(40)),

            // Contenedor principal de tareas de hoy
            Container(
              width: scaleWidth(486),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052A9), width: 1),
              ),
              child: Column(
                children: [
                  // Encabezado de la sección
                  Container(
                    height: scaleHeight(93),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5499E3),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Próximas tareas a realizar',
                      style: TextStyle(
                        fontSize: scaleHeight(24),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Cuerpo que contiene las tareas de hoy
                  Container(
                    padding: EdgeInsets.all(scaleWidth(16)),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB3FFFF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: scaleHeight(8)),
                        Text(
                          'Tareas para hoy',
                          style: TextStyle(
                            fontSize: scaleHeight(35),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: scaleHeight(8)),

                        // Indicador de carga o lista de tareas
                        _isLoadingToday
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: scaleHeight(20)),
                                  child: const CircularProgressIndicator(),
                                ),
                              )
                            : _todayTasks.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: scaleHeight(20)),
                                    child: Text(
                                      'No hay tareas para hoy',
                                      style: TextStyle(
                                        fontSize: scaleHeight(24),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _todayTasks.take(4).map((task) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            bottom: scaleHeight(8)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ',
                                              style: TextStyle(
                                                fontSize: scaleHeight(28),
                                                fontWeight: FontWeight.w600,
                                                color: _getPriorityColor(
                                                    task.priority),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    task.title,
                                                    style: TextStyle(
                                                      fontSize:
                                                          scaleHeight(28),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      decoration:
                                                          task.isCompleted
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                      color: task.isCompleted
                                                          ? Colors.grey
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  if (task
                                                      .description.isNotEmpty)
                                                    Text(
                                                      task.description,
                                                      style: TextStyle(
                                                        fontSize:
                                                            scaleHeight(20),
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: scaleHeight(18),
                                                        color: Colors.grey[600],
                                                      ),
                                                      SizedBox(
                                                          width:
                                                              scaleWidth(4)),
                                                      Text(
                                                        DateFormat('HH:mm')
                                                            .format(task.date),
                                                        style: TextStyle(
                                                          fontSize:
                                                              scaleHeight(18),
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(29)),

            // Contenedor de tareas para mañana
            Container(
              width: scaleWidth(486),
              constraints: BoxConstraints(
                minHeight: scaleHeight(280),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB3FFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052A9), width: 1),
              ),
              padding: EdgeInsets.all(scaleWidth(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '(fecha ${DateFormat('dd/MM/yyyy').format(_tomorrow)})',
                    style: TextStyle(
                      fontSize: scaleHeight(35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),
                  _isLoadingTomorrow
                      ? Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: scaleHeight(20)),
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : _tomorrowTasks.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: scaleHeight(20)),
                              child: Text(
                                'No hay tareas para mañana',
                                style: TextStyle(
                                  fontSize: scaleHeight(24),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _tomorrowTasks.take(2).map((task) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: scaleHeight(8)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: scaleHeight(28),
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _getPriorityColor(task.priority),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: scaleHeight(28),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(50)),

            // Botón que lleva al resumen personal
            SizedBox(
              width: scaleWidth(382),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052A9),
                  padding: EdgeInsets.symmetric(vertical: scaleHeight(14)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ResumenPersonalScreen()),
                  );
                },
                child: Text(
                  'VER RESUMEN PERSONAL',
                  style: TextStyle(
                    fontSize: scaleHeight(24),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: scaleHeight(30)),
          ],
        ),
      ),
    );
  }

  // Retorna un color dependiendo de la prioridad de la tarea
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
}
