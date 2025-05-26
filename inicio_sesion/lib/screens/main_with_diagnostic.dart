import 'package:flutter/material.dart';
import 'package:inicio_sesion/screens/notification_diagnostic_simple.dart';
import 'package:inicio_sesion/screens/notification_test_screen_improved.dart';


class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routiny',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routiny - Pruebas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Herramientas de Prueba de Notificaciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
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
              label: const Text('Pantalla de Pruebas Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
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
              label: const Text('Herramienta de Diagnóstico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Ejecuta primero el Diagnóstico para verificar el estado'),
                    Text('2. Usa la Pantalla de Pruebas para probar funcionalidades'),
                    Text('3. Copia el reporte si encuentras problemas'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}