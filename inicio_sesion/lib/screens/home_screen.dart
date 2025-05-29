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
  final List<Task> _todayTasks = [];
  final List<Task> _tomorrowTasks = [];
  bool _isLoadingToday = true;
  bool _isLoadingTomorrow = true;
  late FirebaseService _firebaseService;
  late DateTime _tomorrow;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadTasks();
  }

  void _initializeServices() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);
    _tomorrow = DateTime.now().add(const Duration(days: 1));
  }

  void _loadTasks() {
    _loadTaskList(_loadTodayTasks, (tasks) {
      if (mounted) setState(() => _todayTasks
        ..clear()
        ..addAll(_sortTasks(tasks)));
    }, () {
      if (mounted) setState(() => _isLoadingToday = false);
    });

    _loadTaskList(_loadTomorrowTasks, (tasks) {
      if (mounted) setState(() => _tomorrowTasks
        ..clear()
        ..addAll(_sortTasks(tasks)));
    }, () {
      if (mounted) setState(() => _isLoadingTomorrow = false);
    });
  }

  void _loadTaskList(
    Future<void> Function() loadFunction,
    Function(List<Task>) onData,
    Function() onError,
  ) {
    loadFunction().then((_) => onData).catchError((_) => onError());
  }

  Future<void> _loadTodayTasks() async {
    if (!mounted) return;
    setState(() => _isLoadingToday = true);
    final today = DateTime.now().toDateOnly();
    return _firebaseService.getTasksByDate(today).first.then((tasks) {
      if (mounted) setState(() {
        _todayTasks
          ..clear()
          ..addAll(_sortTasks(tasks));
      });
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingToday = false);
    });
  }

  Future<void> _loadTomorrowTasks() async {
    if (!mounted) return;
    setState(() => _isLoadingTomorrow = true);
    return _firebaseService.getTasksByDate(_tomorrow).first.then((tasks) {
      if (mounted) setState(() {
        _tomorrowTasks
          ..clear()
          ..addAll(_sortTasks(tasks));
      });
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingTomorrow = false);
    });
  }

  List<Task> _sortTasks(List<Task> tasks) {
    return tasks..sort((a, b) {
      // Mover tareas completadas al final
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      
      // Ordenar por prioridad (descendente)
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      
      // Ordenar por hora
      return a.date.compareTo(b.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    double scaleWidth(double value) => value * screenWidth / 720;
    double scaleHeight(double value) => value * screenHeight / 1280;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
      child: Center(
        child: Column(
          children: [
            SizedBox(height: scaleHeight(40)),
            _buildTaskContainer(
              context,
              title: 'Tareas para hoy',
              tasks: _todayTasks,
              isLoading: _isLoadingToday,
              maxTasks: 5,
              showDetails: true,
              scaleWidth: scaleWidth,
              scaleHeight: scaleHeight,
            ),
            SizedBox(height: scaleHeight(29)),
            _buildTaskContainer(
              context,
              title: 'Tareas para mañana',
              tasks: _tomorrowTasks,
              isLoading: _isLoadingTomorrow,
              maxTasks: 3,
              showDetails: false,
              scaleWidth: scaleWidth,
              scaleHeight: scaleHeight,
            ),
            SizedBox(height: scaleHeight(50)),
            _buildSummaryButton(scaleWidth, scaleHeight),
            SizedBox(height: scaleHeight(30)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskContainer(
    BuildContext context, {
    required String title,
    required List<Task> tasks,
    required bool isLoading,
    required int maxTasks,
    required bool showDetails,
    required double Function(double) scaleWidth,
    required double Function(double) scaleHeight,
  }) {
    return Container(
      width: scaleWidth(486),
      constraints: BoxConstraints(minHeight: scaleHeight(280)),
      decoration: BoxDecoration(
        color: const Color(0xFFBDFFF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0052A9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskHeader(title, scaleHeight),
          Padding(
            padding: EdgeInsets.all(scaleWidth(16)),
            child: isLoading
                ? _buildLoadingIndicator(scaleHeight)
                : tasks.isEmpty
                    ? _buildEmptyState(title, scaleHeight)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tasks
                            .take(maxTasks)
                            .map((task) => _buildTaskItem(
                                  task,
                                  showDetails,
                                  scaleWidth,
                                  scaleHeight,
                                ))
                            .toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(String title, double Function(double) scaleHeight) {
    return Container(
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
          title,
          style: TextStyle(
            fontSize: scaleHeight(35),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(double Function(double) scaleHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(String title, double Function(double) scaleHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleHeight(20)),
      child: Text(
        'No hay $title'.toLowerCase(),
        style: TextStyle(
          fontSize: scaleHeight(24),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    Task task,
    bool showDetails,
    double Function(double) scaleWidth,
    double Function(double) scaleHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: scaleHeight(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriorityIndicator(task.priority, scaleHeight),
          Expanded(
            child: showDetails
                ? _buildDetailedTask(task, scaleHeight)
                : _buildSimpleTask(task, scaleHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority, double Function(double) scaleHeight) {
    return Container(
      width: scaleHeight(20),
      height: scaleHeight(20),
      margin: EdgeInsets.only(
        top: scaleHeight(5),
        right: scaleWidth(6),
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getPriorityColor(priority),
      ),
    );
  }

  Widget _buildDetailedTask(Task task, double Function(double) scaleHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            fontSize: scaleHeight(28),
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black,
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
            overflow: TextOverflow.ellipsis,
          ),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: scaleHeight(18),
              color: Colors.grey[600],
            ),
            SizedBox(width: scaleWidth(4)),
            Text(
              DateFormat('HH:mm').format(task.date),
              style: TextStyle(
                fontSize: scaleHeight(18),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleTask(Task task, double Function(double) scaleHeight) {
    return Text(
      task.title,
      style: TextStyle(
        fontSize: scaleHeight(28),
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSummaryButton(
    double Function(double) scaleWidth,
    double Function(double) scaleHeight,
  ) {
    return SizedBox(
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
    );
  }

  Color _getPriorityColor(int priority) {
    return const [
      Colors.green,  // Prioridad baja (1)
      Colors.orange, // Prioridad media (2)
      Colors.red,    // Prioridad alta (3)
    ][priority - 1];
  }
}

extension DateOnlyCompare on DateTime {
  DateTime toDateOnly() {
    return DateTime(year, month, day);
  }
}