import 'package:flutter/material.dart';
import '../models/hobby.dart';
import '../services/local_storage_service.dart';
import 'hobby_form_screen.dart';
import 'hobby_detail_screen.dart';
import '../services/firebase_service.dart';

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
      final firebaseService = FirebaseService();

      // 1. Obtener desde Firebase
      final firebaseHobbies = await firebaseService.getUserHobbies();

      // 2. Guardar en almacenamiento local
      await _storageService.saveHobbies(firebaseHobbies);

      // 3. Leer localmente y mostrar
      final localHobbies = await _storageService.getHobbies();

      setState(() {
        _hobbies = localHobbies;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar hobbies desde Firebase: $e');
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.self_improvement, // Puedes cambiarlo por otro si prefieres
                                size: MediaQuery.of(context).size.width * 0.25,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No hay hobbies registrados',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toca el botón + para agregar tu primer hobby',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                      itemCount: _hobbies.length,
                      itemBuilder: (context, index) {
                        final hobby = _hobbies[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HobbyDetailScreen(hobby: hobby),
                              ),
                            ).then((result) async {
                              if (result == true) {
                                // El hobby fue eliminado
                                final updatedHobbies = await _storageService.getHobbies();
                                setState(() {
                                  _hobbies = updatedHobbies;
                                });
                              } else if (result != null && result is Hobby) {
                                // El hobby fue editado
                                setState(() {
                                  _hobbies[index] = result;
                                });
                                _storageService.updateHobby(result);
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
        onPressed: () async {
          // Esperar el resultado del formulario
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HobbyFormScreen()),
          );

          // Verificar si se devolvió un Hobby válido
          if (result != null && result is Hobby) {
            setState(() {
              _hobbies.add(result); // Agregar directamente el hobby recibido
            });

            // Guardar también localmente
            await _storageService.addHobby(result);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}