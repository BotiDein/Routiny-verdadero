import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationTestSimple extends StatefulWidget {
  const NotificationTestSimple({Key? key}) : super(key: key);

  @override
  State<NotificationTestSimple> createState() => _NotificationTestSimpleState();
}

class _NotificationTestSimpleState extends State<NotificationTestSimple> {
  final NotificationService _notificationService = NotificationService();
  List<String> _testResults = [];
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  bool _notificationsEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAndCheck();
  }

  Future<void> _initializeAndCheck() async {
    await _checkInitialization();
    await _checkPermissions();
    await _checkDeviceSettings();
  }

  Future<void> _checkInitialization() async {
    try {
      await _notificationService.init();
      setState(() {
        _isInitialized = _notificationService.isInitialized;
      });
      _addResult('✅ NotificationService inicializado correctamente');
    } catch (e) {
      _addResult('❌ Error al inicializar: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final granted = await _notificationService.requestPermissions();
      setState(() {
        _permissionsGranted = granted;
      });
      _addResult(granted 
        ? '✅ Permisos de notificación otorgados' 
        : '❌ Permisos de notificación denegados');
    } catch (e) {
      _addResult('❌ Error al verificar permisos: $e');
    }
  }

  Future<void> _checkDeviceSettings() async {
    try {
      final enabled = await _notificationService.areNotificationsEnabledOnDevice();
      setState(() {
        _notificationsEnabled = enabled;
      });
      _addResult(enabled 
        ? '✅ Notificaciones habilitadas en el dispositivo' 
        : '❌ Notificaciones deshabilitadas en el dispositivo');
    } catch (e) {
      _addResult('❌ Error al verificar configuración del dispositivo: $e');
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }

  Future<void> _testImmediateNotification() async {
    try {
      await _notificationService.showTestNotification();
      _addResult('✅ Notificación inmediata enviada');
      
      // Esperar un poco y verificar si se mostró
      await Future.delayed(const Duration(seconds: 2));
      _addResult('ℹ️ Verifica si apareció la notificación en la barra de estado');
    } catch (e) {
      _addResult('❌ Error en notificación inmediata: $e');
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      // Crear una notificación programada simple usando el plugin directamente
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Canal de Prueba',
        channelDescription: 'Canal para pruebas de notificaciones',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notificationService.flutterLocalNotificationsPlugin.show(
        999,
        'Notificación Programada',
        'Esta notificación se programó hace 10 segundos',
        notificationDetails,
      );
      
      _addResult('✅ Notificación programada enviada');
    } catch (e) {
      _addResult('❌ Error en notificación programada: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      _addResult('✅ Todas las notificaciones canceladas');
    } catch (e) {
      _addResult('❌ Error al cancelar notificaciones: $e');
    }
  }

  Future<void> _getPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationService
          .flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      
      _addResult('📋 Notificaciones pendientes: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        _addResult('  • ID: ${notification.id}, Título: ${notification.title}');
      }
      
      if (pendingNotifications.isEmpty) {
        _addResult('ℹ️ No hay notificaciones pendientes');
      }
    } catch (e) {
      _addResult('❌ Error al obtener notificaciones pendientes: $e');
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas Básicas de Notificaciones'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Estado del sistema
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado del Sistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatusRow('Inicializado', _isInitialized),
                _buildStatusRow('Permisos', _permissionsGranted),
                _buildStatusRow('Habilitado en dispositivo', _notificationsEnabled),
              ],
            ),
          ),
          
          // Botones de prueba
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildTestButton(
                    'Verificar Estado',
                    'Revisar inicialización y permisos',
                    Icons.check_circle,
                    Colors.blue,
                    _initializeAndCheck,
                  ),
                  _buildTestButton(
                    'Notificación Inmediata',
                    'Mostrar notificación ahora mismo',
                    Icons.notifications_active,
                    Colors.green,
                    _testImmediateNotification,
                  ),
                  _buildTestButton(
                    'Notificación Simple',
                    'Probar notificación básica',
                    Icons.schedule,
                    Colors.orange,
                    _testScheduledNotification,
                  ),
                  _buildTestButton(
                    'Ver Notificaciones Pendientes',
                    'Listar notificaciones programadas',
                    Icons.list,
                    Colors.indigo,
                    _getPendingNotifications,
                  ),
                  _buildTestButton(
                    'Cancelar Todas',
                    'Cancelar todas las notificaciones',
                    Icons.cancel,
                    Colors.red,
                    _cancelAllNotifications,
                  ),
                ],
              ),
            ),
          ),
          
          // Resultados
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resultados de Pruebas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _clearResults,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Limpiar resultados',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            result,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: result.contains('❌') 
                                ? Colors.red 
                                : result.contains('✅') 
                                  ? Colors.green 
                                  : Colors.black87,
                            ),
                          ),
                        );
                      },
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

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
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
}