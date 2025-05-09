import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Calculamos valores relativos basados en el tamaño de la pantalla
    final smallFontSize = screenWidth * 0.035; // 3.5% para texto pequeño
    final navBarHeight = screenHeight * 0.08; // 8% de la altura de la pantalla

    return Container(
      // Decoración para añadir color de fondo y sombra
      decoration: const BoxDecoration(
        color: Color(0xFF4A90E2), // Azul
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, -1), // Sombra hacia arriba
          ),
        ],
      ),
      // SafeArea evita que los elementos se coloquen en áreas inseguras (notch, etc.)
      child: SafeArea(
        child: SizedBox(
          height: navBarHeight, // Altura relativa a la pantalla
          // Organiza los elementos en una fila horizontal
          child: Row(
            // Distribuye los elementos uniformemente
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Los 5 elementos de navegación
              _buildNavItem(0, Icons.trending_up, 'Hábitos', screenWidth, smallFontSize),
              _buildNavItem(1, Icons.book, 'Agenda', screenWidth, smallFontSize),
              _buildNavItem(2, Icons.home, 'Inicio', screenWidth, smallFontSize),
              _buildNavItem(3, Icons.calendar_today, 'Calendario', screenWidth, smallFontSize),
              _buildNavItem(4, Icons.sports_esports, 'Hobbies', screenWidth, smallFontSize),
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir cada elemento de la barra de navegación
  Widget _buildNavItem(int index, IconData icon, String label, double screenWidth, double fontSize) {
    // Determina si este elemento está seleccionado actualmente
    final bool isSelected = selectedIndex == index;
    
    // Ancho de cada elemento como porcentaje del ancho de pantalla
    final itemWidth = screenWidth * 0.18; // 18% del ancho de pantalla
    
    return InkWell(
      // Al tocar, llama al método onItemTapped con el índice correspondiente
      onTap: () => onItemTapped(index),
      child: Container(
        width: itemWidth,
        padding: EdgeInsets.symmetric(vertical: fontSize * 0.3),
        // Decoración del contenedor
        decoration: BoxDecoration(
          // Si está seleccionado, usa un color de fondo azul claro, si no, transparente
          color: isSelected ? const Color(0xFF81B4F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(fontSize * 0.8), // Bordes redondeados
        ),
        // Organiza icono y texto en una columna
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa el mínimo espacio vertical
          mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
          children: [
            // Icono de navegación
            Icon(
              icon,
              color: Colors.black,
              size: fontSize * 1.5, // 1.5 veces el tamaño de la fuente
            ),
            SizedBox(height: fontSize * 0.2), // Pequeño espacio entre icono y texto
            // Texto de navegación
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize * 0.9, // 90% del tamaño de fuente base
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center, // Centra el texto
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Maneja texto que no cabe
            ),
          ],
        ),
      ),
    );
  }
}