import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/local_storage_service.dart';
import '../screens/habit_form_screen.dart';
import 'dart:math' as math;

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final habits = await _storageService.getHabits();
      
      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar hábitos: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar hábitos: $e';
          _isLoading = false;
        });
      }
    }
  }

// Modificar los métodos para usar fechas específicas en lugar de días de la semana

// Modificar el método _incrementHabit
void _incrementHabit(int index) async {
  if (index < 0 || index >= _habits.length) return;
  
  try {
    final habit = _habits[index];
    
    if (habit.type == 'count') {
      final current = habit.current is int ? habit.current as int : 0;
      final goal = habit.goal is int ? habit.goal as int : 0;
      
      if (goal == 0 || current < goal) {
        // Crear una copia del hábito con el valor actualizado
        final updatedDays = List<int>.from(habit.days);
        final today = DateTime.now().weekday % 7;
        
        // Actualizar el estado del día actual
        if (goal > 0 && current + 1 >= goal) {
          updatedDays[today] = 2; // Completado
        } else {
          updatedDays[today] = 1; // Parcial
        }
        
        // Actualizar el mapa de fechas específicas
        final todayStr = _formatDate(DateTime.now());
        final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
        updatedCompletedDates[todayStr] = goal > 0 && current + 1 >= goal ? 2 : 1;
        
        final updatedHabit = habit.copyWith(
          current: current + 1,
          days: updatedDays,
          completedDates: updatedCompletedDates,
        );
        
        // Actualizar la UI primero
        setState(() {
          _habits[index] = updatedHabit;
        });
        
        // Depurar fechas completadas
        _debugPrintCompletedDates(updatedHabit);
        
        // Guardar en almacenamiento local
        await _storageService.updateHabit(updatedHabit);
      }
    }
  } catch (e) {
    print('Error al incrementar hábito: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }
}

// Modificar el método _decrementHabit
void _decrementHabit(int index) async {
  if (index < 0 || index >= _habits.length) return;
  
  try {
    final habit = _habits[index];
    
    if (habit.type == 'count') {
      final current = habit.current is int ? habit.current as int : 0;
      
      if (current > 0) {
        // Crear una copia del hábito con el valor actualizado
        final updatedDays = List<int>.from(habit.days);
        final today = DateTime.now().weekday % 7;
        final goal = habit.goal is int ? habit.goal as int : 0;
        
        // Actualizar el estado del día actual
        if (current - 1 <= 0) {
          updatedDays[today] = 0; // No registrado
        } else if (goal > 0 && current - 1 < goal) {
          updatedDays[today] = 1; // Parcial
        }
        
        // Actualizar el mapa de fechas específicas
        final todayStr = _formatDate(DateTime.now());
        final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
        if (current - 1 <= 0) {
          updatedCompletedDates.remove(todayStr); // Eliminar si no hay progreso
        } else {
          updatedCompletedDates[todayStr] = goal > 0 && current - 1 < goal ? 1 : 2;
        }
        
        final updatedHabit = habit.copyWith(
          current: current - 1,
          days: updatedDays,
          completedDates: updatedCompletedDates,
        );
        
        // Actualizar la UI primero
        setState(() {
          _habits[index] = updatedHabit;
        });
        
        // Guardar en almacenamiento local
        await _storageService.updateHabit(updatedHabit);
      }
    }
  } catch (e) {
    print('Error al decrementar hábito: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }
}

// Modificar el método _toggleBooleanHabit
void _toggleBooleanHabit(int index) async {
  if (index < 0 || index >= _habits.length) return;
  
  try {
    final habit = _habits[index];
    
    if (habit.type == 'boolean') {
      final current = habit.current is bool ? habit.current as bool : false;
      
      // Crear una copia del hábito con el valor actualizado
      final updatedDays = List<int>.from(habit.days);
      final today = DateTime.now().weekday % 7;
      
      // Actualizar el estado del día actual
      updatedDays[today] = !current ? 2 : 0; // 2 = completado, 0 = no registrado
      
      // Actualizar el mapa de fechas específicas
      final todayStr = _formatDate(DateTime.now());
      final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
      if (!current) {
        updatedCompletedDates[todayStr] = 2; // Completado
      } else {
        updatedCompletedDates.remove(todayStr); // Eliminar si se desmarca
      }
      
      final updatedHabit = habit.copyWith(
        current: !current,
        days: updatedDays,
        completedDates: updatedCompletedDates,
      );
      
      // Actualizar la UI primero
      setState(() {
        _habits[index] = updatedHabit;
      });
      
      // Guardar en almacenamiento local
      await _storageService.updateHabit(updatedHabit);
    }
  } catch (e) {
    print('Error al cambiar hábito booleano: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }
}

// Modificar el método _showRegisterTimeDialog
void _showRegisterTimeDialog(int index) {
  if (index < 0 || index >= _habits.length) return;
  
  final habit = _habits[index];
  String currentTime = habit.current is String ? habit.current as String : '00:00:00';
  
  // Extraer horas, minutos y segundos del tiempo actual
  List<String> timeParts = currentTime.split(':');
  int hours = int.tryParse(timeParts[0]) ?? 0;
  int minutes = int.tryParse(timeParts[1]) ?? 0;
  int seconds = int.tryParse(timeParts[2]) ?? 0;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Registrar Tiempo'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: 180,
              child: Column(
                children: [
                  const Text('Selecciona el tiempo a registrar:'),
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
            onPressed: () async {
              try {
                // Actualizar el tiempo del hábito
                final newTime =
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                
                // Crear una copia del hábito con el valor actualizado
                final updatedDays = List<int>.from(habit.days);
                final today = DateTime.now().weekday % 7;
                final goalTime = habit.goal is String ? habit.goal as String : '00:00:00';
                
                // Determinar el estado basado en el progreso
                int status = 0;
                if (hours > 0 || minutes > 0 || seconds > 0) {
                  // Comparar con el objetivo
                  List<String> goalParts = goalTime.split(':');
                  int goalHours = int.tryParse(goalParts[0]) ?? 0;
                  int goalMinutes = int.tryParse(goalParts[1]) ?? 0;
                  int goalSeconds = int.tryParse(goalParts[2]) ?? 0;
                  
                  int totalSeconds = hours * 3600 + minutes * 60 + seconds;
                  int goalTotalSeconds = goalHours * 3600 + goalMinutes * 60 + goalSeconds;
                  
                  if (totalSeconds >= goalTotalSeconds && goalTotalSeconds > 0) {
                    status = 2; // Completado
                  } else {
                    status = 1; // Parcial
                  }
                }
                
                updatedDays[today] = status;
                
                // Actualizar el mapa de fechas específicas
                final todayStr = _formatDate(DateTime.now());
                final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
                if (status > 0) {
                  updatedCompletedDates[todayStr] = status;
                } else {
                  updatedCompletedDates.remove(todayStr);
                }
                
                final updatedHabit = habit.copyWith(
                  current: newTime,
                  days: updatedDays,
                  completedDates: updatedCompletedDates,
                );
                
                // Actualizar la UI primero
                setState(() {
                  _habits[index] = updatedHabit;
                });
                
                // Guardar en almacenamiento local
                await _storageService.updateHabit(updatedHabit);
                
                Navigator.of(context).pop();
              } catch (e) {
                print('Error al guardar tiempo: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al guardar: $e')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}

// Asegurémonos de que estamos guardando correctamente las fechas en el formato adecuado
// Modificar el método _formatDate para asegurarnos de que el formato sea correcto

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// También vamos a añadir un método de depuración para verificar las fechas guardadas
// Añadir este método después de _formatDate

void _debugPrintCompletedDates(Habit habit) {
  print('Hábito: ${habit.name}');
  print('Fechas completadas:');
  habit.completedDates.forEach((date, status) {
    print('  $date: $status');
  });
}

  Future<void> _showAddHabitScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HabitFormScreen(),
      ),
    );
    
    if (result != null && result is Habit) {
      try {
        await _storageService.addHabit(result);
        _loadHabits();
      } catch (e) {
        print('Error al añadir hábito: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      }
    }
  }

  Future<void> _editHabit(int index) async {
    if (index < 0 || index >= _habits.length) return;
    
    final habit = _habits[index];
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitFormScreen(
          habit: habit,
          isEditing: true,
        ),
      ),
    );
    
    if (result != null && result is Habit) {
      try {
        await _storageService.updateHabit(result);
        _loadHabits();
      } catch (e) {
        print('Error al actualizar hábito: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      }
    }
  }

  void _deleteHabit(int index) {
    if (index < 0 || index >= _habits.length) return;
    
    final habit = _habits[index];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar hábito'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este hábito?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Eliminar de la UI primero
                  setState(() {
                    _habits.removeAt(index);
                  });
                  
                  // Eliminar del almacenamiento local
                  await _storageService.deleteHabit(habit.id);
                  
                  Navigator.pop(context);
                } catch (e) {
                  print('Error al eliminar hábito: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                  Navigator.pop(context);
                  
                  // Recargar hábitos en caso de error
                  _loadHabits();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFE0FFFF),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Ocurrió un error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHabits,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _habits.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay hábitos registrados.\nPresiona el botón + para agregar uno.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _habits.length,
                        itemBuilder: (context, index) {
                          final habit = _habits[index];
                          final habitType = habit.type;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: const Color(0xFFB3E5FC), // Color azul claro
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _editHabit(index),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            habit.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteHabit(index),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildDayCircle('D', habit.days.length > 0 ? habit.days[0] : 0),
                                          _buildDayCircle('L', habit.days.length > 1 ? habit.days[1] : 0),
                                          _buildDayCircle('M', habit.days.length > 2 ? habit.days[2] : 0),
                                          _buildDayCircle('X', habit.days.length > 3 ? habit.days[3] : 0),
                                          _buildDayCircle('J', habit.days.length > 4 ? habit.days[4] : 0),
                                          _buildDayCircle('V', habit.days.length > 5 ? habit.days[5] : 0),
                                          _buildDayCircle('S', habit.days.length > 6 ? habit.days[6] : 0),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Mostrar progreso según el tipo de hábito
                                        if (habitType == 'count') ...[
                                          Text(
                                            '${habit.current}/${habit.goal}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                                onPressed:
                                                    () => _decrementHabit(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                                onPressed:
                                                    () => _incrementHabit(index),
                                              ),
                                            ],
                                          ),
                                        ] else if (habitType == 'time') ...[
                                          Text(
                                            '${habit.current}/${habit.goal}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.timer),
                                            onPressed:
                                                () => _showRegisterTimeDialog(index),
                                          ),
                                        ] else if (habitType == 'boolean') ...[
                                          Text(
                                            habit.current == true
                                                ? 'Completado'
                                                : 'Pendiente',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  habit.current == true
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              habit.current == true
                                                  ? Icons.check_circle
                                                  : Icons.check_circle_outline,
                                              color:
                                                  habit.current == true
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                            onPressed:
                                                () => _toggleBooleanHabit(index),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: _showAddHabitScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDayCircle(String day, int status) {
    // status: 0 = no registrado (rojo), 1 = parcial (amarillo), 2 = completado (verde)
    Color color;
    switch (status) {
      case 0:
        color = Colors.red;
        break;
      case 1:
        color = Colors.amber;
        break;
      case 2:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(
          day,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
