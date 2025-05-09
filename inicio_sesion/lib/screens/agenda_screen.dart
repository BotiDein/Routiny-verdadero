import 'package:flutter/material.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  // Método que se llama cuando se toca una tarea
  void _onTaskTapped(String taskName) {
    // Aquí se podría implementar la lógica para ver detalles de la tarea
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tarea seleccionada: $taskName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Calculamos valores relativos basados en el tamaño de la pantalla
    final isTablet = screenWidth > 600;
    
    // Padding horizontal como porcentaje del ancho de pantalla
    final horizontalPadding = screenWidth * 0.04; // 4% del ancho de pantalla
    
    // Tamaños de texto relativos al ancho de pantalla
    final headerFontSize = screenWidth * 0.045; // 4.5% para encabezados
    final bodyFontSize = screenWidth * 0.04; // 4% para texto normal
    final smallFontSize = screenWidth * 0.035; // 3.5% para texto pequeño
    
    // Tamaños de iconos relativos
    final mediumIconSize = screenWidth * 0.05; // 5% para iconos medianos
    final smallIconSize = screenWidth * 0.04; // 4% para iconos pequeños

    return Scaffold(
      body: SingleChildScrollView(
        // Permite desplazamiento si el contenido es más grande que la pantalla
        child: Padding(
          // Añade padding horizontal según el tamaño del dispositivo
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          // Organiza los elementos en una columna vertical
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.025), // 2.5% de la altura como espacio superior
              // Sección de fecha "Hoy"
              _buildDateSection('Hoy', headerFontSize),
              SizedBox(height: screenHeight * 0.015), // 1.5% de espacio entre elementos
              // Primera tarea del día
              _buildTaskButton(
                icon: Icons.favorite_border, // Icono de corazón
                title: 'Cita medica // Ortodoncia',
                bodyFontSize: bodyFontSize,
                smallFontSize: smallFontSize,
                iconSize: mediumIconSize,
                smallIconSize: smallIconSize,
              ),
              SizedBox(height: screenHeight * 0.02), // 2% de espacio entre tareas
              // Segunda tarea del día
              _buildTaskButton(
                icon: Icons.face, // Icono de cara
                title: 'Entregar informe mensual',
                bodyFontSize: bodyFontSize,
                smallFontSize: smallFontSize,
                iconSize: mediumIconSize,
                smallIconSize: smallIconSize,
              ),
              SizedBox(height: screenHeight * 0.025), // 2.5% de espacio entre secciones
              // Sección de fecha futura
              _buildDateSection('10 Mayo 2025', headerFontSize),
              SizedBox(height: screenHeight * 0.015), // 1.5% de espacio entre elementos
              // Tarea para la fecha futura
              _buildBillButton(
                title: 'Pagar servicios',
                subtitle: 'Pagar agua, gas, y luz. Son 120.000 pesos',
                bodyFontSize: bodyFontSize,
                smallFontSize: smallFontSize,
                smallIconSize: smallIconSize,
              ),
              // Espacio adicional al final para que el FAB no tape contenido
              SizedBox(height: screenHeight * 0.1), // 10% de espacio al final
            ],
          ),
        ),
      ),
      // Botón flotante para añadir nuevas tareas
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0047AB), // Azul oscuro
        child: Icon(Icons.add, color: Colors.white, size: mediumIconSize),
        onPressed: () {
          // Aquí iría la lógica para añadir una nueva tarea
        },
      ),
    );
  }

  // Método para construir las secciones de fecha
  Widget _buildDateSection(String date, double fontSize) {
    return Container(
      width: double.infinity, // Ocupa todo el ancho disponible
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.7), // Padding relativo al tamaño de fuente
      // Decoración del contenedor
      decoration: BoxDecoration(
        color: const Color(0xFFADD8E6), // Azul claro
        borderRadius: BorderRadius.circular(fontSize * 0.5), // Radio relativo al tamaño de fuente
      ),
      child: Text(
        date,
        textAlign: TextAlign.center, // Centra el texto
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Método para construir los botones de tareas con icono
  Widget _buildTaskButton({
    required IconData icon, // Icono a mostrar
    required String title, // Título de la tarea
    required double bodyFontSize, // Tamaño de fuente para el texto principal
    required double smallFontSize, // Tamaño de fuente para texto pequeño
    required double iconSize, // Tamaño para el icono principal
    required double smallIconSize, // Tamaño para iconos pequeños
  }) {
    return Material(
      color: Colors.transparent, // Fondo transparente
      child: InkWell(
        // InkWell proporciona el efecto de ondulación al tocar
        onTap: () => _onTaskTapped(title),
        borderRadius: BorderRadius.circular(bodyFontSize * 0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: bodyFontSize * 0.5),
          // Organiza el icono y texto en una fila
          child: Row(
            children: [
              // Contenedor circular para el icono
              Container(
                padding: EdgeInsets.all(bodyFontSize * 0.6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: bodyFontSize * 0.1),
                  shape: BoxShape.circle, // Forma circular
                ),
                child: Icon(icon, size: iconSize), // Tamaño relativo
              ),
              SizedBox(width: bodyFontSize * 0.8), // Espacio entre icono y texto
              // El texto ocupa el espacio disponible
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: bodyFontSize, // Tamaño relativo
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Icono de flecha a la derecha para indicar que es interactivo
              Icon(
                Icons.arrow_forward_ios,
                size: smallIconSize,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir los botones de tareas tipo factura (sin icono circular)
  Widget _buildBillButton({
    required String title, // Título principal
    required String subtitle, // Subtítulo o descripción
    required double bodyFontSize, // Tamaño de fuente para el texto principal
    required double smallFontSize, // Tamaño de fuente para texto pequeño
    required double smallIconSize, // Tamaño para iconos pequeños
  }) {
    return Material(
      color: Colors.transparent, // Fondo transparente
      child: InkWell(
        // InkWell proporciona el efecto de ondulación al tocar
        onTap: () => _onTaskTapped(title),
        borderRadius: BorderRadius.circular(bodyFontSize * 0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: bodyFontSize * 0.5),
          // Organiza el contenido en una fila
          child: Row(
            children: [
              // El texto ocupa el espacio disponible
              Expanded(
                // Organiza título y subtítulo en una columna
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinea a la izquierda
                  children: [
                    // Título principal
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: bodyFontSize * 1.1, // Ligeramente más grande que el texto normal
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: smallFontSize * 0.3), // Espacio entre título y subtítulo
                    // Subtítulo o descripción
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey[700], // Color gris para el subtítulo
                      ),
                    ),
                  ],
                ),
              ),
              // Icono de flecha a la derecha para indicar que es interactivo
              Icon(
                Icons.arrow_forward_ios,
                size: smallIconSize,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}