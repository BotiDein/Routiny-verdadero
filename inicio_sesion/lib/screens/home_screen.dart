import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Funciones para escalar medidas en pantallas diferentes
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

            // Tarjeta: Próximas tareas a realizar
            Container(
              width: scaleWidth(486),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052A9), width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
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
                  Container(
                    width: double.infinity,
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
                        // Lista de tareas ficticias
                        ...List.generate(
                          5,
                          (i) => Text(
                            '• Tarea ${i + 1}',
                            style: TextStyle(
                              fontSize: scaleHeight(28),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: scaleHeight(16)),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Mostrar más',
                            style: TextStyle(
                              fontSize: scaleHeight(20),
                              color: const Color(0xFF0052A9),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(29)),

            // Tarjeta: Tareas por fecha (estática por ahora)
            Container(
              width: scaleWidth(486),
              height: scaleHeight(280),
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
                    '(fecha 10/04/2025)',
                    style: TextStyle(
                      fontSize: scaleHeight(35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: scaleHeight(8)),
                  Text(
                    '• Tarea 1',
                    style: TextStyle(
                      fontSize: scaleHeight(28),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• Tarea 2',
                    style: TextStyle(
                      fontSize: scaleHeight(28),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Mostrar más',
                      style: TextStyle(
                        fontSize: scaleHeight(20),
                        color: const Color(0xFF0052A9),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: scaleHeight(50)),

            // Botón para ver el resumen personal
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
                onPressed: () {}, // Acción pendiente para el resumen
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
}