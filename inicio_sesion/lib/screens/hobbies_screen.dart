import 'package:flutter/material.dart';
import '../models/hobby.dart';
import '../services/local_storage_service.dart';
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
  final LocalStorageService _storageService = LocalStorageService();
  List<Hobby> _hobbies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHobbies();
  }
  
  // Cargar hobbies al iniciar la pantalla
  Future<void> _loadHobbies() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hobbies = await _storageService.getHobbies();
      setState(() {
        _hobbies = hobbies;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar hobbies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _hobbies.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay hobbies registrados.\nPresiona el botón + para agregar uno.',
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _hobbies.length,
                      itemBuilder: (context, index) {
                        final hobby = _hobbies[index];
                        return InkWell(
                          onTap: () {
                            // Navegar a la pantalla de detalles del hobby
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HobbyDetailScreen(hobby: hobby),
                              ),
                            ).then((updatedHobby) {
                              if (updatedHobby != null && updatedHobby is Hobby) {
                                setState(() {
                                  _hobbies[index] = updatedHobby;
                                  _storageService.updateHobby(updatedHobby);
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
                                    hobby.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      hobby.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    hobby.time,
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
          ).then((result) {
            if (result != null && result is Map<String, dynamic>) {
              // Convertir el mapa a un objeto Hobby
              final newHobby = Hobby(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: result['name'] ?? '',
                icon: result['icon'] ?? '😊',
                time: result['time'] ?? '00:00:00',
                weeklyGoal: result['weeklyGoal'] ?? '05:00:00',
                registeredTimes: List<Map<String, dynamic>>.from(result['registeredTimes'] ?? []),
                activeDays: List<int>.from(result['activeDays'] ?? []),
              );
              
              setState(() {
                _hobbies.add(newHobby);
                _storageService.addHobby(newHobby);
              });
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}