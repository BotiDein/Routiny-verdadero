import 'package:flutter/material.dart';
import 'hobby_form_screen.dart';
import 'hobby_detail_screen.dart';

// Clase singleton para mantener los datos de los hobbies
class HobbiesData {
  // Instancia única
  static final HobbiesData _instance = HobbiesData._internal();
  
  // Lista de hobbies que persiste entre navegaciones
  final List<Map<String, dynamic>> hobbies = [];
  
  // Constructor factory que devuelve la instancia única
  factory HobbiesData() {
    return _instance;
  }
  
  // Constructor privado
  HobbiesData._internal();
}

class HobbiesScreen extends StatefulWidget {
  const HobbiesScreen({super.key});

  @override
  State<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends State<HobbiesScreen> {
  // Usar la instancia singleton para acceder a los hobbies
  final _hobbiesData = HobbiesData();

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
                _hobbiesData.hobbies.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay hobbies registrados.\nPresiona el botón + para agregar uno.',
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _hobbiesData.hobbies.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            // Navegar a la pantalla de detalles del hobby
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => HobbyDetailScreen(
                                      hobby: _hobbiesData.hobbies[index],
                                    ),
                              ),
                            ).then((result) {
                              // Actualizar el tiempo si se modificó en la pantalla de detalles
                              if (result != null && result is Map<String, dynamic>) {
                                setState(() {
                                  // Actualizar el hobby con los datos que regresan
                                  _hobbiesData.hobbies[index] = result;
                                });
                              }
                            });
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
                                    _hobbiesData.hobbies[index]['icon'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _hobbiesData.hobbies[index]['name'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    _hobbiesData.hobbies[index]['time'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.alarm, size: 20),
                                  const Icon(Icons.chevron_right, size: 40)
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
                _hobbiesData.hobbies.add(newHobby);
              });
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}