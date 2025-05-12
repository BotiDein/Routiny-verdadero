import 'package:flutter/material.dart';

class ResumenPersonalScreen extends StatelessWidget {
  const ResumenPersonalScreen({super.key});

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(scaleWidth(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: scaleHeight(16)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Abril 2024',
                style: TextStyle(
                  fontSize: scaleFont(26),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: scaleHeight(16)),

            // Círculo de porcentaje
            Container(
              width: scaleWidth(250),
              height: scaleWidth(250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0052A9),
                  width: scaleWidth(18),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '91%',
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
            ),

            SizedBox(height: scaleHeight(30)),

            // Gráfico de tiempo dedicado (falso estático)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tiempo dedicado',
                style: TextStyle(
                  fontSize: scaleFont(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: scaleHeight(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _barraActividad('Estudio', 0.8, Colors.blue.shade900, screenHeight),
                _barraActividad('Hobbies', 0.3, Colors.lightBlue, screenHeight),
                _barraActividad('Trabajo', 0.5, Colors.cyanAccent, screenHeight),
                _barraActividad('Otros', 0.7, Colors.blue.shade700, screenHeight),
              ],
            ),

            SizedBox(height: scaleHeight(40)),

            // Estadísticas
            Container(
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
                  _estadisticaItem(Icons.local_fire_department, Colors.red, 'Racha más larga', '7 días', scaleFont),
                  _estadisticaItem(Icons.whatshot, Colors.orange, 'Racha actual', '4 días', scaleFont),
                  _estadisticaItem(Icons.emoji_events, Colors.amber[800]!, 'Tareas completadas', '9', scaleFont),
                ],
              ),
            ),
            SizedBox(height: scaleHeight(30)),
          ],
        ),
      ),
    );
  }

  Widget _barraActividad(String label, double factor, Color color, double screenHeight) {
    return Column(
      children: [
        Container(
          width: 30,
          height: screenHeight * 0.15 * factor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _estadisticaItem(IconData icon, Color color, String label, String valor, double Function(double) scaleFont) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: scaleFont(20), fontWeight: FontWeight.bold),
          ),
          Text(
            valor,
            style: TextStyle(fontSize: scaleFont(20)),
          ),
        ],
      ),
    );
  }
}
