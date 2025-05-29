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

  void _loadTasks() {
    _loadTodayTasks();
    _loadTomorrowTasks();
  }

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

    _firebaseService
        .getTasksByDate(today)
        .listen(
          (tasks) {
            if (mounted) {
              setState(() {
                // Ordenar tareas por prioridad (alta a baja) y hora, con completadas al final
                tasks.sort((a, b) {
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

  void _loadTomorrowTasks() {
    if (!mounted) return;

    setState(() {
      _isLoadingTomorrow = true;
    });

    _firebaseService
        .getTasksByDate(_tomorrow)
        .listen(
          (tasks) {
            if (mounted) {
              setState(() {
                // Ordenar tareas por prioridad (alta a baja) y hora, con completadas al final
                tasks.sort((a, b) {
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

            // Contenedor de tareas para hoy
            Container(
              width: scaleWidth(486),
              constraints: BoxConstraints(minHeight: scaleHeight(280)),
              decoration: BoxDecoration(
                color: Color(0xFFBDFFF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052A9), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: scaleHeight(10)),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052A9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tareas para hoy',
                        style: TextStyle(
                          fontSize: scaleHeight(35),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(scaleWidth(16)),
                    child:
                        _isLoadingToday
                            ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: scaleHeight(20),
                                ),
                                child: const CircularProgressIndicator(),
                              ),
                            )
                            : _todayTasks.isEmpty
                            ? Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: scaleHeight(20),
                              ),
                              child: Text(
                                'No hay tareas para hoy',
                                style: TextStyle(
                                  fontSize: scaleHeight(24),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  _todayTasks.take(5).map((task) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: scaleHeight(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: scaleHeight(20),
                                            height: scaleHeight(20),
                                            margin: EdgeInsets.only(
                                              top: scaleHeight(5),
                                              right: scaleWidth(6),
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _getPriorityColor(
                                                task.priority,
                                              ),
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
                                                    fontSize: scaleHeight(28),
                                                    fontWeight: FontWeight.w600,
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
                                                if (task.description.isNotEmpty)
                                                  Text(
                                                    task.description,
                                                    style: TextStyle(
                                                      fontSize: scaleHeight(20),
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
                                                      width: scaleWidth(4),
                                                    ),
                                                    Text(
                                                      DateFormat(
                                                        'HH:mm',
                                                      ).format(task.date),
                                                      style: TextStyle(
                                                        fontSize: scaleHeight(
                                                          18,
                                                        ),
                                                        color: Colors.grey[600],
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
                  ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(29)),

            // Contenedor de tareas para mañana
            Container(
              width: scaleWidth(486),
              constraints: BoxConstraints(minHeight: scaleHeight(280)),
              decoration: BoxDecoration(
                color: Color(0xFFBDFFF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052A9), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: scaleHeight(10)),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052A9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tareas para mañana',
                        style: TextStyle(
                          fontSize: scaleHeight(35),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(scaleWidth(16)),
                    child:
                        _isLoadingTomorrow
                            ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: scaleHeight(20),
                                ),
                                child: const CircularProgressIndicator(),
                              ),
                            )
                            : _tomorrowTasks.isEmpty
                            ? Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: scaleHeight(20),
                              ),
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
                              children:
                                  _tomorrowTasks.take(3).map((task) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: scaleHeight(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: scaleHeight(20),
                                            height: scaleHeight(20),
                                            margin: EdgeInsets.only(
                                              top: scaleHeight(5),
                                              right: scaleWidth(6),
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _getPriorityColor(
                                                task.priority,
                                              ),
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
                  ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(50)),

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
                      builder: (context) => const ResumenPersonalScreen(),
                    ),
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