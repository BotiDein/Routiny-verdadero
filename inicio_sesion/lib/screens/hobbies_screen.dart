import 'package:flutter/material.dart';
import 'hobby_form_screen.dart';
import 'hobby_detail_screen.dart';

class HobbiesScreen extends StatefulWidget {
  const HobbiesScreen({super.key});

  @override
  State<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends State<HobbiesScreen> {
  final List<Map<String, dynamic>> _hobbies = [
    {'name': 'Escuchar música', 'icon': '😊', 'time': '00:00:00'},
    {'name': 'Practicar a tocar piano', 'icon': '😐', 'time': '00:00:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Lista de Hobbies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child:
                _hobbies.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay hobbies registrados.\nPresiona el botón + para agregar uno.',
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _hobbies.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            // Navegar a la pantalla de detalles del hobby
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => HobbyDetailScreen(
                                      hobby: _hobbies[index],
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _hobbies[index]['icon'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _hobbies[index]['name'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    _hobbies[index]['time'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.alarm, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: () {
          // Navegar a la pantalla para agregar un nuevo hobby
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HobbyFormScreen()),
          ).then((newHobby) {
            if (newHobby != null) {
              setState(() {
                _hobbies.add(newHobby);
              });
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
