import 'package:flutter/material.dart';
import '../services/notification_manager.dart';
import '../services/notification_service.dart';
import '../models/task.dart';

class NotificationDiagnosticScreen extends StatefulWidget {
  const NotificationDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<NotificationDiagnosticScreen> createState() => _NotificationDiagnosticScreenState();
}

class _NotificationDiagnosticScreenState extends State<NotificationDiagnosticScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, dynamic> _diagnosticData = {};
  bool _isLoading = true;
  String _lastTestResult = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    final diagnostics = <String, dynamic>{};

    try {
      // Verificar inicialización usando el getter público
      diagnostics['manager_initialized'] = _notificationManager.isInitialized;
      diagnostics['service_initialized'] = _notificationService.isInitialized;
      
      // Verificar permisos
      diagnostics['permissions_granted'] = await _notificationService.requestPermissions();
      
      // Verificar notificaciones del dispositivo
      diagnostics['device_notifications_enabled'] = await _notificationService.areNotificationsEnabledOnDevice();
      
      // Verificar configuraciones de la app
      diagnostics['app_notifications_enabled'] = await _notificationManager.areNotificationsEnabled();
      diagnostics['task_notifications_enabled'] = await _notificationManager.areTaskNotificationsEnabled();
      diagnostics['habit_notifications_enabled'] = await _notificationManager.areHabitNotificationsEnabled();
      diagnostics['streak_notifications_enabled'] = await _notificationManager.areStreakNotificationsEnabled();
      diagnostics['hobby_notifications_enabled'] = await _notificationManager.areHobbyNotificationsEnabled();
      
      // Verificar racha actual
      diagnostics['current_streak'] = await _notificationManager.getCurrentStreak();
      
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    setState(() {
      _diagnosticData = diagnostics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Notificaciones'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiagnosticSection(),
                  const SizedBox(height: 24),
                  _buildTestSection(),
                  if (_lastTestResult.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildResultSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDiagnosticSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._diagnosticData.entries.map((entry) {
              return _buildDiagnosticItem(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(String key, dynamic value) {
    Color color = Colors.grey;
    IconData icon = Icons.help;
    
    if (value is bool) {
      color = value ? Colors.green : Colors.red;
      icon = value ? Icons.check_circle : Icons.error;
    } else if (value is int) {
      color = Colors.blue;
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatKey(key),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pruebas de Notificación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testImmediateNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                ),
                child: const Text(
                  'Probar Notificación Inmediata',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testDelayedNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  'Probar Notificación en 10s',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testHabitReminders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Probar Recordatorios de Hábitos',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reinitializeSystem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: const Text(
                  'Reinicializar Sistema',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      color: _lastTestResult.contains('Error') ? Colors.red[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado de la Prueba',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _lastTestResult.contains('Error') ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastTestResult,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testImmediateNotification() async {
    try {
      setState(() {
        _lastTestResult = 'Enviando notificación inmediata...';
      });
      
      await _notificationManager.showTestNotification();
      setState(() {
        _lastTestResult = 'Notificación inmediata enviada correctamente. Verifica tu bandeja de notificaciones.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error al enviar notificación inmediata: $e';
      });
    }
  }

  Future<void> _testDelayedNotification() async {
    try {
      setState(() {
        _lastTestResult = 'Programando notificación...';
      });
      
      final now = DateTime.now();
      final futureTime = now.add(const Duration(seconds: 10));
      
      final task = Task(
        id: 'test_${now.millisecondsSinceEpoch}',
        title: 'Tarea de Prueba',
        description: 'Esta es una tarea de prueba',
        date: futureTime,
        createdAt: now,
      );
      
      await _notificationManager.scheduleTaskNotification(task);
      
      setState(() {
        _lastTestResult = 'Notificación programada para ${futureTime.hour}:${futureTime.minute.toString().padLeft(2, '0')}:${futureTime.second.toString().padLeft(2, '0')}. Espera 10 segundos.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error al programar notificación: $e';
      });
    }
  }

  Future<void> _testHabitReminders() async {
    try {
      setState(() {
        _lastTestResult = 'Programando recordatorios de hábitos...';
      });
      
      await _notificationManager.scheduleHabitReminders();
      
      setState(() {
        _lastTestResult = 'Recordatorios de hábitos programados correctamente para las 8:00 AM y 6:00 PM.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error al programar recordatorios de hábitos: $e';
      });
    }
  }

  Future<void> _reinitializeSystem() async {
    try {
      setState(() {
        _lastTestResult = 'Reinicializando sistema...';
      });
      
      await _notificationManager.initialize();
      await _runDiagnostics();
      
      setState(() {
        _lastTestResult = 'Sistema reinicializado correctamente.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error al reinicializar sistema: $e';
      });
    }
  }
}