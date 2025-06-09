import 'package:flutter/material.dart';
import '../widgets/category_dialog.dart';
import '../models/habit.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;
  final bool isEditing;

  const HabitFormScreen({super.key, this.habit, this.isEditing = false});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Ejercicio';
  String _selectedType = 'time';
  String _selectedOption = 'Al menos';
  bool _isGoalEnabled = true;

  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  int _regHours = 0;
  int _regMinutes = 0;
  int _regSeconds = 0;

  final List<String> _categories = [
    'Ejercicio', 'Salud', 'Educación', 'Trabajo', 
    'Personal', 'Finanzas', 'Hobbies', 'Otros',
  ];

  final List<String> _options = [
    'Al menos', 'Marca de', 'Exactamente', 'Sin objetivo',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.habit != null) {
      _loadHabitData();
    }
  }

  void _loadHabitData() {
    _titleController.text = widget.habit!.name;
    _descriptionController.text = widget.habit!.description;
    _selectedCategory = widget.habit!.category;
    _selectedType = widget.habit!.type == 'count' ? 'time' : widget.habit!.type;

    if (widget.habit!.type == 'count' || widget.habit!.type == 'time') {
      _selectedOption = widget.habit!.option;
      _isGoalEnabled = _selectedOption != 'Sin objetivo';

      if (widget.habit!.goal != null) {
        if (widget.habit!.type == 'time' && widget.habit!.goal is String) {
          final timeParts = (widget.habit!.goal as String).split(':');
          if (timeParts.length == 3) {
            _hours = int.tryParse(timeParts[0]) ?? 0;
            _minutes = int.tryParse(timeParts[1]) ?? 0;
            _seconds = int.tryParse(timeParts[2]) ?? 0;
          }
        } else if (widget.habit!.type == 'count' && widget.habit!.goal is int) {
          _minutes = (widget.habit!.goal as int);
          _hours = 0;
          _seconds = 0;
        }
      }
    }

    final today = DateTime.now().weekday % 7;
    if (widget.habit!.registeredTimes!.containsKey(today.toString())) {
      final regTime = widget.habit!.registeredTimes![today.toString()];
      if (regTime != null) {
        final timeParts = regTime.split(':');
        if (timeParts.length == 3) {
          _regHours = int.tryParse(timeParts[0]) ?? 0;
          _regMinutes = int.tryParse(timeParts[1]) ?? 0;
          _regSeconds = int.tryParse(timeParts[2]) ?? 0;
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

    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final timeSelectorSize = isSmallScreen ? MediaQuery.of(context).size.width * 0.18 : 80.0;
    final fontSize = isSmallScreen ? 16.0 : 24.0;
    final labelFontSize = isSmallScreen ? 12.0 : 14.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Seleccionar Tiempo',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: isSmallScreen ? 150 : 180,
                child: Column(
                  children: [
                    Text(
                      'Selecciona el tiempo objetivo:',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSelector(
                          'Horas', 
                          hours, 
                          (val) => hours = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 23
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildTimeSelector(
                          'Minutos', 
                          minutes, 
                          (val) => minutes = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 59
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildTimeSelector(
                          'Segundos', 
                          seconds, 
                          (val) => seconds = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 59
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
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
              child: Text(
                'Aceptar',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSelector(
    String label, 
    int value, 
    Function(int) onChanged, 
    double width, 
    double fontSize, 
    double labelFontSize,
    {int max = 59, int min = 0}
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: labelFontSize),
          ),
          IconButton(
            icon: Icon(Icons.arrow_drop_up, size: isSmallScreen ? 24 : 30),
            onPressed: () => onChanged(value < max ? value + 1 : value),
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(fontSize: fontSize),
          ),
          IconButton(
            icon: Icon(Icons.arrow_drop_down, size: isSmallScreen ? 24 : 30),
            onPressed: () => onChanged(value > min ? value - 1 : value),
          ),
        ],
      ),
    );
  }

  void _showRegisteredTimePickerDialog() {
    int hours = _regHours;
    int minutes = _regMinutes;
    int seconds = _regSeconds;

    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final timeSelectorSize = isSmallScreen ? MediaQuery.of(context).size.width * 0.18 : 80.0;
    final fontSize = isSmallScreen ? 16.0 : 24.0;
    final labelFontSize = isSmallScreen ? 12.0 : 14.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Registrar Tiempo',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: isSmallScreen ? 150 : 180,
                child: Column(
                  children: [
                    Text(
                      '¿Cuánto tiempo dedicaste hoy?',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSelector(
                          'Horas', 
                          hours, 
                          (val) => hours = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 23
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildTimeSelector(
                          'Minutos', 
                          minutes, 
                          (val) => minutes = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 59
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 16),
                        _buildTimeSelector(
                          'Segundos', 
                          seconds, 
                          (val) => seconds = val, 
                          timeSelectorSize, 
                          fontSize, 
                          labelFontSize,
                          max: 59
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _regHours = hours;
                  _regMinutes = minutes;
                  _regSeconds = seconds;
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Guardar',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        );
      },
    );
  }

  String get _formattedTime {
    return '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedRegisteredTime {
    return '${_regHours.toString().padLeft(2, '0')}:${_regMinutes.toString().padLeft(2, '0')}:${_regSeconds.toString().padLeft(2, '0')}';
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
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final inputFontSize = isSmallScreen ? 14.0 : 16.0;
    final buttonFontSize = isSmallScreen ? 14.0 : 16.0;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Editar hábito' : 'Nuevo hábito',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
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
            color: const Color(0xFFE0FFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Categoría', titleFontSize),
                      const SizedBox(height: 8),
                      _buildCategorySelector(isSmallScreen),
                      const SizedBox(height: 16),
                      
                      _buildSectionTitle('Tipo de hábito', titleFontSize),
                      const SizedBox(height: 8),
                      _buildTypeOptions(isSmallScreen),
                      const SizedBox(height: 16),
                      
                      _buildSectionTitle('Título', titleFontSize),
                      const SizedBox(height: 8),
                      _buildTitleInput(inputFontSize, isSmallScreen),
                      const SizedBox(height: 16),
                      
                      if (_selectedType == 'time') ...[
                        _buildTimeOptions(titleFontSize, inputFontSize, isSmallScreen),
                        const SizedBox(height: 16),
                        _buildRegisteredTimeSection(titleFontSize, inputFontSize, isSmallScreen),
                        const SizedBox(height: 16),
                      ],
                      
                      _buildSectionTitle('Descripción:', titleFontSize),
                      const SizedBox(height: 8),
                      _buildDescriptionInput(inputFontSize, isSmallScreen),
                    ],
                  ),
                ),
              ),
              
              _buildBottomButtons(buttonFontSize, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategorySelector(bool isSmallScreen) {
    return GestureDetector(
      onTap: _showCategoryDialog,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _selectedCategory,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTypeOptions(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(child: _buildTypeOption('Por tiempo', Icons.timer_outlined, 'time', isSmallScreen)),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(child: _buildTypeOption('Hecho/Pendiente', Icons.check_circle_outline, 'boolean', isSmallScreen)),
      ],
    );
  }

  Widget _buildTitleInput(double fontSize, bool isSmallScreen) {
    return TextField(
      controller: _titleController,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: 'Texto',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 14,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildTimeOptions(double titleFontSize, double inputFontSize, bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildOptionDropdown(titleFontSize, isSmallScreen)),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(child: _buildTimeGoalSelector(inputFontSize, isSmallScreen)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionDropdown(double fontSize, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Opción', fontSize),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
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
                child: Text(
                  option,
                  style: TextStyle(fontSize: fontSize),
                ),
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
    );
  }

  Widget _buildTimeGoalSelector(double fontSize, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tiempo objetivo', fontSize),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isGoalEnabled ? _showTimePickerDialog : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: _isGoalEnabled ? Colors.white : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isGoalEnabled ? Colors.grey.shade300 : Colors.grey.shade400,
              ),
            ),
            child: Text(
              _isGoalEnabled ? _formattedTime : 'No disponible',
              style: TextStyle(
                fontSize: fontSize,
                color: _isGoalEnabled ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredTimeSection(double titleFontSize, double inputFontSize, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tiempo registrado hoy', titleFontSize),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showRegisteredTimePickerDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formattedRegisteredTime,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.black,
                  ),
                ),
                Icon(
                  Icons.timer,
                  color: const Color(0xFF4A90E2),
                  size: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(double fontSize, bool isSmallScreen) {
    return TextField(
      controller: _descriptionController,
      style: TextStyle(fontSize: fontSize),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Describe tu nuevo hábito.',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      ),
    );
  }

  Widget _buildBottomButtons(double fontSize, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(isSmallScreen ? 100 : 120, isSmallScreen ? 40 : 45),
              textStyle: TextStyle(fontSize: fontSize),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(isSmallScreen ? 100 : 120, isSmallScreen ? 40 : 45),
              textStyle: TextStyle(fontSize: fontSize),
            ),
            child: Text(widget.isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _saveHabit() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un título')),
      );
      return;
    }

    if (_selectedType == 'time' && _isGoalEnabled) {
      final timeParts = _formattedTime.split(':').map(int.parse).toList();
      final totalSeconds = timeParts[0] * 3600 + timeParts[1] * 60 + timeParts[2];

      if (totalSeconds < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un tiempo objetivo mayor a 00:00:00'),
          ),
        );
        return;
      }
    }

    final habit = Habit(
      id: widget.isEditing 
          ? widget.habit!.id 
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      type: _selectedType,
      option: _selectedType == 'boolean' ? 'Sin objetivo' : _selectedOption,
      goal: _selectedType == 'time' 
          ? (_isGoalEnabled ? _formattedTime : '00:00:00')
          : null,
      current: _selectedType == 'time'
          ? (widget.isEditing && widget.habit?.type == 'time'
              ? widget.habit!.current
              : '00:00:00')
          : (widget.isEditing && widget.habit?.type == 'boolean'
              ? widget.habit!.current
              : false),
      amount: int.tryParse(_amountController.text) ?? 1,
      days: widget.isEditing ? widget.habit!.days : [0, 0, 0, 0, 0, 0, 0],
      createdAt: widget.isEditing ? widget.habit!.createdAt : DateTime.now(),
      completedDates: widget.isEditing ? widget.habit!.completedDates : {},
      registeredTimes: _selectedType == 'time'
          ? (widget.isEditing && widget.habit?.registeredTimes != null
              ? Map<String, String>.from(widget.habit!.registeredTimes)
              : {})..[DateTime.now().weekday % 7.toString()] = _formattedRegisteredTime
          : null,
    );

    Navigator.pop(context, habit);
  }

  Widget _buildTypeOption(String title, IconData icon, String type, bool isSmallScreen) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 6 : 8,
          horizontal: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4A90E2).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF4A90E2) : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}