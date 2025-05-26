import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../services/notification_service.dart';

class NotificationDiagnosticTool extends StatefulWidget {
  const NotificationDiagnosticTool({Key? key}) : super(key: key);

  @override
  State<NotificationDiagnosticTool> createState() => _NotificationDiagnosticToolState();
}

class _NotificationDiagnosticToolState extends State<NotificationDiagnosticTool> {
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic> _diagnosticData = {};
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _diagnosticData.clear();
    });

    try {
      // Información básica del dispositivo
      await _getBasicDeviceInfo();
      
      // Estado del servicio de notificaciones
      await _getNotificationServiceStatus();
      
      // Configuración del sistema
      await _getSystemConfiguration();
      
      // Pruebas básicas
      await _runBasicTests();
      
    } catch (e) {
      _diagnosticData['error'] = e.toString();
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _getBasicDeviceInfo() async {
    try {
      _diagnosticData['device'] = {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'isAndroid': Platform.isAndroid,
        'isIOS': Platform.isIOS,
        'locale': Platform.localeName,
      };
    } catch (e) {
      _diagnosticData['device'] = {'error': e.toString()};
    }
  }

  Future<void> _getNotificationServiceStatus() async {
    try {
      // Intentar inicializar el servicio
      bool initSuccess = false;
      String initError = '';
      
      try {
        await _notificationService.init();
        initSuccess = true;
      } catch (e) {
        initError = e.toString();
      }
      
      // Verificar permisos
      bool permissionsGranted = false;
      String permissionError = '';
      
      try {
        permissionsGranted = await _notificationService.requestPermissions();
      } catch (e) {
        permissionError = e.toString();
      }
      
      // Verificar si están habilitadas en el dispositivo
      bool deviceEnabled = false;
      String deviceError = '';
      
      try {
        deviceEnabled = await _notificationService.areNotificationsEnabledOnDevice();
      } catch (e) {
        deviceError = e.toString();
      }
      
      // Obtener racha actual
      int currentStreak = 0;
      try {
        currentStreak = await _notificationService.getCurrentStreak();
      } catch (e) {
        // Ignorar error de racha
      }
      
      // Obtener notificaciones pendientes
      int pendingCount = 0;
      List<Map<String, dynamic>> pendingDetails = [];
      
      try {
        final pendingNotifications = await _notificationService
            .flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
        
        pendingCount = pendingNotifications.length;
        pendingDetails = pendingNotifications.map((n) => {
          'id': n.id,
          'title': n.title ?? 'Sin título',
          'body': n.body ?? 'Sin contenido',
        }).toList();
      } catch (e) {
        // Ignorar error de pendientes
      }
      
      _diagnosticData['notificationService'] = {
        'initialized': initSuccess,
        'initError': initError,
        'permissionsGranted': permissionsGranted,
        'permissionError': permissionError,
        'deviceEnabled': deviceEnabled,
        'deviceError': deviceError,
        'currentStreak': currentStreak,
        'pendingNotifications': pendingCount,
        'pendingDetails': pendingDetails,
      };
    } catch (e) {
      _diagnosticData['notificationService'] = {'error': e.toString()};
    }
  }

  Future<void> _getSystemConfiguration() async {
    try {
      final now = DateTime.now();
      _diagnosticData['systemConfig'] = {
        'timezone': now.timeZoneName,
        'timeOffset': now.timeZoneOffset.toString(),
        'currentTime': now.toString(),
        'currentTimeFormatted': '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}',
        'platform': Platform.operatingSystem,
        'dartVersion': Platform.version,
      };
    } catch (e) {
      _diagnosticData['systemConfig'] = {'error': e.toString()};
    }
  }

  Future<void> _runBasicTests() async {
    final tests = <String, dynamic>{};
    
    // Test 1: Verificar inicialización
    try {
      await _notificationService.init();
      tests['initialization'] = 'PASS';
    } catch (e) {
      tests['initialization'] = 'FAIL: $e';
    }
    
    // Test 2: Verificar permisos
    try {
      final hasPermissions = await _notificationService.requestPermissions();
      tests['permissions'] = hasPermissions ? 'PASS' : 'FAIL: Permisos denegados';
    } catch (e) {
      tests['permissions'] = 'FAIL: $e';
    }
    
    // Test 3: Verificar configuración del dispositivo
    try {
      final deviceEnabled = await _notificationService.areNotificationsEnabledOnDevice();
      tests['deviceConfig'] = deviceEnabled ? 'PASS' : 'FAIL: Notificaciones deshabilitadas';
    } catch (e) {
      tests['deviceConfig'] = 'FAIL: $e';
    }
    
    // Test 4: Intentar mostrar notificación de prueba
    try {
      await _notificationService.showTestNotification();
      tests['testNotification'] = 'PASS: Notificación enviada';
    } catch (e) {
      tests['testNotification'] = 'FAIL: $e';
    }
    
    _diagnosticData['tests'] = tests;
  }

  String _generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== REPORTE DE DIAGNÓSTICO DE NOTIFICACIONES ===');
    buffer.writeln('Generado: ${DateTime.now()}');
    buffer.writeln('App: Routiny');
    buffer.writeln();
    
    _diagnosticData.forEach((section, data) {
      buffer.writeln('[$section]');
      if (data is Map) {
        data.forEach((key, value) {
          if (value is List) {
            buffer.writeln('  $key:');
            for (var item in value) {
              buffer.writeln('    - $item');
            }
          } else {
            buffer.writeln('  $key: $value');
          }
        });
      } else {
        buffer.writeln('  $data');
      }
      buffer.writeln();
    });
    
    // Agregar recomendaciones
    buffer.writeln('[RECOMENDACIONES]');
    
    final notifService = _diagnosticData['notificationService'] as Map?;
    if (notifService != null) {
      if (notifService['initialized'] != true) {
        buffer.writeln('  • Revisar inicialización del servicio de notificaciones');
      }
      if (notifService['permissionsGranted'] != true) {
        buffer.writeln('  • Otorgar permisos de notificación en Configuración > Apps > Routiny');
      }
      if (notifService['deviceEnabled'] != true) {
        buffer.writeln('  • Habilitar notificaciones en Configuración del dispositivo');
      }
    }
    
    final tests = _diagnosticData['tests'] as Map?;
    if (tests != null) {
      tests.forEach((test, result) {
        if (result.toString().startsWith('FAIL')) {
          buffer.writeln('  • Solucionar problema en test: $test');
        }
      });
    }
    
    return buffer.toString();
  }

  Future<void> _copyReportToClipboard() async {
    final report = _generateReport();
    await Clipboard.setData(ClipboardData(text: report));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte copiado al portapapeles'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Notificaciones'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar diagnóstico',
          ),
          IconButton(
            onPressed: _copyReportToClipboard,
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar reporte',
          ),
        ],
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ejecutando diagnóstico...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('Información del Dispositivo', _diagnosticData['device']),
                _buildSection('Servicio de Notificaciones', _diagnosticData['notificationService']),
                _buildSection('Configuración del Sistema', _diagnosticData['systemConfig']),
                _buildSection('Resultados de Pruebas', _diagnosticData['tests']),
                
                const SizedBox(height: 20),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _runDiagnostic,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _copyReportToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar Reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón de prueba rápida
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _notificationService.showTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificación de prueba enviada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Enviar Notificación de Prueba'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            if (data == null)
              const Text('No hay datos disponibles')
            else if (data is Map)
              ...data.entries.map((entry) => _buildDataRow(entry.key, entry.value))
            else
              Text(data.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: value is List
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: value.map((item) => Text('• $item')).toList(),
                  )
                : Text(
                    value.toString(),
                    style: TextStyle(
                      color: _getValueColor(value),
                      fontFamily: value.toString().length > 50 ? 'monospace' : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    final valueStr = value.toString().toLowerCase();
    if (valueStr.contains('true') || valueStr.contains('pass')) {
      return Colors.green;
    } else if (valueStr.contains('false') || valueStr.contains('fail')) {
      return Colors.red;
    } else if (valueStr.contains('error')) {
      return Colors.red;
    }
    return Colors.black87;
  }
}