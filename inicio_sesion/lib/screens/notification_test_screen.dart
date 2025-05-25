import 'package:flutter/material.dart';
import '../services/notification_manager.dart';
import '../models/task.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  bool _isLoading = false;
  String _statusMessage = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Notificaciones'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta pantalla te permite probar el sistema de notificaciones',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testImmediateNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Enviar notificación inmediata',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDelayedNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Enviar notificación en 10 segundos',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testHabitReminders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Programar recordatorios de hábitos',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testStreakReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Programar recordatorio de racha',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _testImmediateNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      await _notificationManager.showTestNotification();
      setState(() {
        _statusMessage = 'Notificación enviada correctamente. Verifica tu bandeja de notificaciones.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al enviar notificación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testDelayedNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      // Crear una tarea ficticia para 10 segundos en el futuro
      final now = DateTime.now();
      final futureTime = now.add(const Duration(seconds: 10));
      
      final task = Task(
        id: 'test_task_${now.millisecondsSinceEpoch}',
        title: 'Tarea de prueba',
        description: 'Esta es una tarea de prueba para notificaciones',
        date: futureTime,
        createdAt: now,
      );
      
      await _notificationManager.scheduleTaskNotification(task);
      
      setState(() {
        _statusMessage = 'Notificación programada para ${futureTime.hour}:${futureTime.minute}:${futureTime.second}. Espera 10 segundos.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al programar notificación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testHabitReminders() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      //await _notificationManager.scheduleHabitReminders();
      
      setState(() {
        _statusMessage = 'Recordatorios de hábitos programados para las 8:00 AM y 6:00 PM.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al programar recordatorios de hábitos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testStreakReminder() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      // Asegurar que haya una racha
      await _notificationManager.updateStreak();
      
      setState(() {
        _statusMessage = 'Racha actualizada y recordatorio programado para las 8:00 PM.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al programar recordatorio de racha: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
