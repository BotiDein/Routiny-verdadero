import 'package:flutter/material.dart';

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
  final TextEditingController _weeklyGoalController = TextEditingController();
  
  String _selectedEmoji = '😊';
  
  final List<String> _emojis = [
      '😊', '🏃', '🧠', '📚', '💼', '🍎', '💪', '🧘', '🎯', '⚽',
      '🎮', '🎨', '🎵', '🍳', '🌱', '💻', '🏠', '🚗', '✈️', '🛒',
      '💰', '🎓', '🔬', '🧪', '🧬', '🔭', '📱', '📷', '🎬', '📺',
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
        if (parts.isNotEmpty) {
          _weeklyGoalController.text = parts[0]; // Tomamos solo las horas
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar Hobby' : 'Nuevo Hobby',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFD6F9F0),
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
                'Meta semanal (horas)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weeklyGoalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const Spacer(),
              
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      // Crear un nuevo hobby y volver a la pantalla anterior
                      Navigator.pop(context, {
                        'name': _nameController.text,
                        'icon': _selectedEmoji,
                        'time': '00:00:00',
                        'weeklyGoal': _weeklyGoalController.text.isNotEmpty 
                            ? '${_weeklyGoalController.text}:00:00' 
                            : '05:00:00',
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa un nombre para el hobby'),
                        ),
                      );
                    }
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