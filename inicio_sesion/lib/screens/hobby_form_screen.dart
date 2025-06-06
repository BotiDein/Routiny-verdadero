import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../models/hobby.dart';


class HobbyFormScreen extends StatefulWidget {
  final Map<String, dynamic>? hobby;
  final bool isEditing;

  const HobbyFormScreen({
    super.key,
    this.hobby,
    this.isEditing = false,
  });

  @override
  State<HobbyFormScreen> createState() => _HobbyFormScreenState();
}

class _HobbyFormScreenState extends State<HobbyFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weeklyGoalHoursController = TextEditingController();
  final TextEditingController _weeklyGoalMinutesController = TextEditingController();
  
  String _selectedEmoji = '😊';
  
  final List<String> _emojis = [
      '😊', '🏃', '🧠', '📚', '💼', '🍎', '💪', '🧘', '🎯', '⚽', '🥵',
      '🎮', '🎨', '🎵', '🍳', '🌱', '💻', '🏠', '🚗', '✈️', '🛒', '💞',
      '💰', '🎓', '🔬', '🧪', '🧬', '🔭', '📱', '📷', '🎬', '📺', '🐛',
  ];

  @override
  void initState() {
    super.initState();
    
    // Si estamos editando, cargar los datos del hobby
    if (widget.isEditing && widget.hobby != null) {
      _nameController.text = widget.hobby!['name'] ?? '';
      _selectedEmoji = widget.hobby!['icon'] ?? '😊';
      
      // Extraer la meta semanal si existe
      if (widget.hobby!['weeklyGoal'] != null) {
        final parts = widget.hobby!['weeklyGoal'].split(':');
        if (parts.length >= 1) {
          _weeklyGoalHoursController.text = parts[0].padLeft(2, '0');
          if (parts.length > 1) {
            _weeklyGoalMinutesController.text = parts[1].padLeft(2, '0');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weeklyGoalHoursController.dispose();
    _weeklyGoalMinutesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar Hobby' : 'Nuevo Hobby',
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFE0FFFF),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del Hobby
              const Text(
                'Nombre del Hobby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: Leer libros',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Selección de emoji
              const Text(
                'Selecciona un emoji',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = _emojis[index];
                        });
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedEmoji == _emojis[index]
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _emojis[index],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Meta semanal
              const Text(
                'Meta semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weeklyGoalHoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Horas',
                        hintText: 'Ej: 5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _weeklyGoalMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Minutos',
                        hintText: 'Ej: 30',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un nombre para el hobby')),
                      );
                      return;
                    }

                    // 1. Leer horas y minutos de los controladores
                    final hours = int.tryParse(_weeklyGoalHoursController.text) ?? 0;
                    final minutes = int.tryParse(_weeklyGoalMinutesController.text) ?? 0;

                    // 2. Convertir a formato HH:MM:SS
                    final formattedWeeklyGoal = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';

                    // 3. Construir el hobby
                    final hobby = Hobby(
                      id: widget.isEditing &&
                              widget.hobby != null &&
                              widget.hobby is Map<String, dynamic> &&
                              widget.hobby!.containsKey('id')
                          ? widget.hobby!['id'] as String
                          : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      icon: _selectedEmoji,
                      time: '00:00:00',
                      weeklyGoal: formattedWeeklyGoal, // ✅ esta es la correcta
                      registeredTimes: widget.isEditing &&
                              widget.hobby != null &&
                              widget.hobby!.containsKey('registeredTimes')
                          ? List<Map<String, dynamic>>.from(widget.hobby!['registeredTimes'] as List)
                          : <Map<String, dynamic>>[],
                      activeDays: widget.isEditing &&
                              widget.hobby != null &&
                              widget.hobby!.containsKey('activeDays')
                          ? List<int>.from(widget.hobby!['activeDays'] as List)
                          : <int>[],
                    );

                    // 4. Guardar localmente y en Firebase
                    final localStorage = LocalStorageService();
                    await localStorage.addHobby(hobby);

                    final firebaseService = FirebaseService();
                    await firebaseService.saveSingleUserHobby(hobby);

                    // 5. Volver con el nuevo hobby
                    Navigator.pop(context, hobby);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.isEditing ? 'Guardar cambios' : 'Guardar',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}