import 'package:flutter/material.dart';
import '../widgets/category_dialog.dart';
import '../models/habit.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;
  final bool isEditing;

  const HabitFormScreen({
    super.key,
    this.habit,
    this.isEditing = false,
  });

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Ejercicio';
  String _selectedType = 'count'; // 'count', 'time', 'boolean'
  String _selectedOption = 'Al menos';
  bool _isGoalEnabled = true;
  
  // Valores para el selector de tiempo (para tipo 'time')
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  
  final List<String> _categories = [
    'Ejercicio',
    'Salud',
    'Educación',
    'Trabajo',
    'Personal',
    'Finanzas',
    'Hobbies',
    'Otros',
  ];
  
  final List<String> _options = [
    'Al menos',
    'Marca de',
    'Exactamente',
    'Sin objetivo',
  ];

  @override
  void initState() {
    super.initState();
    
    // Si estamos editando, cargar los datos del hábito
    if (widget.isEditing && widget.habit != null) {
      _titleController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description;
      _selectedCategory = widget.habit!.category;
      _selectedType = widget.habit!.type;
      
      if (_selectedType == 'count') {
        _selectedOption = widget.habit!.option;
        if (widget.habit!.goal != null && widget.habit!.goal is int) {
          _goalController.text = (widget.habit!.goal as int).toString();
        }
        _amountController.text = widget.habit!.amount.toString();
        _isGoalEnabled = _selectedOption != 'Sin objetivo';
      } else if (_selectedType == 'time') {
        _selectedOption = widget.habit!.option;
        _isGoalEnabled = _selectedOption != 'Sin objetivo';
        
        // Cargar el tiempo si existe
        if (widget.habit!.goal != null && widget.habit!.goal is String) {
          final timeParts = (widget.habit!.goal as String).split(':');
          if (timeParts.length == 3) {
            _hours = int.tryParse(timeParts[0]) ?? 0;
            _minutes = int.tryParse(timeParts[1]) ?? 0;
            _seconds = int.tryParse(timeParts[2]) ?? 0;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showTimePickerDialog() {
    int hours = _hours;
    int minutes = _minutes;
    int seconds = _seconds;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Tiempo'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 180,
                child: Column(
                  children: [
                    const Text('Selecciona el tiempo objetivo:'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Horas
                        Column(
                          children: [
                            const Text('Horas'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_up),
                                  onPressed: () {
                                    setState(() {
                                      if (hours < 23) hours++;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              hours.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () {
                                    setState(() {
                                      if (hours > 0) hours--;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Minutos
                        Column(
                          children: [
                            const Text('Minutos'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_up),
                                  onPressed: () {
                                    setState(() {
                                      if (minutes < 59) minutes++;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              minutes.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () {
                                    setState(() {
                                      if (minutes > 0) minutes--;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Segundos
                        Column(
                          children: [
                            const Text('Segundos'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_up),
                                  onPressed: () {
                                    setState(() {
                                      if (seconds < 59) seconds++;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              seconds.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () {
                                    setState(() {
                                      if (seconds > 0) seconds--;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _hours = hours;
                  _minutes = minutes;
                  _seconds = seconds;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  String get _formattedTime {
    return '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}';
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CategoryDialog(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar hábito' : 'Nuevo hábito',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0FFFF), // Fondo azul claro
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showCategoryDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Tipo de hábito
                      const Text(
                        'Tipo de hábito',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeOption(
                              'Por conteo',
                              Icons.add_circle_outline,
                              'count',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeOption(
                              'Por tiempo',
                              Icons.timer_outlined,
                              'time',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeOption(
                              'Hecho/Pendiente',
                              Icons.check_circle_outline,
                              'boolean',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Título
                      const Text(
                        'Título',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Texto',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Campos específicos según el tipo de hábito
                      if (_selectedType == 'count') ...[
                        // Opciones y cantidad
                        Row(
                          children: [
                            // Dropdown de opciones
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Opción',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedOption,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items: _options.map((String option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedOption = newValue!;
                                          _isGoalEnabled = newValue != 'Sin objetivo';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Campo de cantidad
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cantidad',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Cantidad',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Objetivo
                        const Text(
                          'Objetivo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _goalController,
                          enabled: _isGoalEnabled,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Tu objetivo final\nEj: 145 páginas',
                            filled: true,
                            fillColor: _isGoalEnabled 
                                ? Colors.white
                                : Colors.grey.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ] else if (_selectedType == 'time') ...[
                        // Opciones y tiempo
                        Row(
                          children: [
                            // Dropdown de opciones
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Opción',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedOption,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items: _options.map((String option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedOption = newValue!;
                                          _isGoalEnabled = newValue != 'Sin objetivo';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Campo de tiempo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tiempo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _isGoalEnabled ? _showTimePickerDialog : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _isGoalEnabled 
                                            ? Colors.white
                                            : Colors.grey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isGoalEnabled 
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: Text(
                                        _isGoalEnabled 
                                            ? _formattedTime
                                            : 'No disponible',
                                        style: TextStyle(
                                          color: _isGoalEnabled ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Descripción
                      const Text(
                        'Descripción:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe tu nuevo hábito.',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botones inferiores
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 45),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Validar y guardar el hábito
                        if (_titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor ingresa un título')),
                          );
                          return;
                        }
                        
                        // Validar según el tipo de hábito
                        if (_selectedType == 'count' && _isGoalEnabled && _goalController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor ingresa un objetivo')),
                          );
                          return;
                        }
                        
                        // Preparar valores según el tipo
                        dynamic goalValue;
                        dynamic currentValue;
                        
                        if (_selectedType == 'count') {
                          goalValue = _isGoalEnabled ? int.tryParse(_goalController.text) ?? 0 : 0;
                          currentValue = widget.isEditing && widget.habit?.type == 'count' 
                              ? widget.habit!.current 
                              : 0;
                        } else if (_selectedType == 'time') {
                          goalValue = _isGoalEnabled ? _formattedTime : '00:00:00';
                          currentValue = widget.isEditing && widget.habit?.type == 'time' 
                              ? widget.habit!.current 
                              : '00:00:00';
                        } else { // boolean
                          goalValue = null;
                          currentValue = widget.isEditing && widget.habit?.type == 'boolean' 
                              ? widget.habit!.current 
                              : false;
                        }
                        
                        // Crear o actualizar el hábito
                        final habit = Habit(
                          id: widget.isEditing ? widget.habit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _titleController.text,
                          description: _descriptionController.text,
                          category: _selectedCategory,
                          type: _selectedType,
                          option: _selectedType == 'boolean' ? 'Sin objetivo' : _selectedOption,
                          goal: goalValue,
                          current: currentValue,
                          amount: int.tryParse(_amountController.text) ?? 1,
                          days: widget.isEditing ? widget.habit!.days : [0, 0, 0, 0, 0, 0, 0],
                          createdAt: widget.isEditing ? widget.habit!.createdAt : DateTime.now(),
                        );
                        
                        Navigator.pop(context, habit);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 45),
                      ),
                      child: Text(
                        widget.isEditing ? 'Guardar' : 'Crear',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    String title, 
    IconData icon, 
    String type,
  ) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
