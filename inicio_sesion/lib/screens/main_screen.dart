import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'agenda_screen.dart';
import 'habits_screen.dart';
import 'hobbies_screen.dart';
import 'settings_screen.dart';
import '../widgets/nav_bar.dart'; // Importamos el widget NavBar

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Iniciar en Inicio (índice 2)
  
  // Lista de títulos para cada página
  final List<String> _pageTitles = [
    'Hábitos',
    'Agenda',
    'Inicio',
    'Calendario',
    'Hobbies',
  ];
  
  // Lista de pantallas para cada sección
  final List<Widget> _screens = [
    const HabitsScreen(),
    const AgendaScreen(),
    const HomeScreen(),
    const CalendarScreen(),
    const HobbiesScreen(),
  ];
  
  // Método para cambiar entre pantallas
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de la pantalla para diseño responsivo
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Escalado dinámico para responsividad
    final horizontalPadding = screenWidth * 0.04;
    final titleFontSize = screenWidth * 0.06;
    final largeIconSize = screenWidth * 0.06;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text(
          _pageTitles[_selectedIndex],
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: largeIconSize, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          SizedBox(width: horizontalPadding / 2),
        ],
      ),
      body: _screens[_selectedIndex],
      // Usamos el widget NavBar reutilizable
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}