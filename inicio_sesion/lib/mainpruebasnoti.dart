import 'package:flutter/material.dart';
import 'screens/notification_test_simple.dart';
import 'screens/notification_diagnostic_simple.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routiny - Pruebas de Notificaciones',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestMenuScreen(),
    );
  }
}

class TestMenuScreen extends StatelessWidget {
  const TestMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routiny - Menú de Pruebas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.notifications_active,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Pruebas de Notificaciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Botón para diagnóstico
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationDiagnosticTool(),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('1. Diagnóstico del Sistema'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para pruebas
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestSimple(),
                  ),
                );
              },
              icon: const Icon(Icons.science),
              label: const Text('2. Pruebas de Notificaciones'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Instrucciones:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('1. Ejecuta primero el DIAGNÓSTICO'),
                  Text('2. Verifica que todo esté en verde'),
                  Text('3. Luego ejecuta las PRUEBAS'),
                  Text('4. Observa las notificaciones en tu dispositivo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}