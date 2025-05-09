import 'package:flutter/material.dart';
import 'habit_form_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // Lista de hábitos
  final List<Map<String, dynamic>> _habits = [
    {
      'name': 'Salir a correr',
      'category': 'Ejercicio',
      'type': 'count',
      'option': 'Al menos',
      'goal': 30,
      'amount': 5,
      'current': 0,
      'description': 'Correr al menos 30 minutos diarios',
      'days': [
        0,
        1,
        2,
        1,
        0,
        1,
        0,
      ], // 0: no registrado, 1: parcial, 2: completado
    },
  ];

  void _incrementHabit(int index) {
    setState(() {
      if (_habits[index]['current'] < _habits[index]['goal']) {
        _habits[index]['current']++;

        // Actualizar el estado del día actual (usamos 0 para domingo, 6 para sábado)
        final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)

        // Determinar el estado basado en el progreso
        if (_habits[index]['current'] >= _habits[index]['goal']) {
          _habits[index]['days'][today] = 2; // Completado (verde)
        } else if (_habits[index]['current'] > 0) {
          _habits[index]['days'][today] = 1; // Parcial (amarillo)
        }
      }
    });
  }

  void _decrementHabit(int index) {
    setState(() {
      if (_habits[index]['current'] > 0) {
        _habits[index]['current']--;

        // Actualizar el estado del día actual
        final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)

        // Determinar el estado basado en el progreso
        if (_habits[index]['current'] <= 0) {
          _habits[index]['days'][today] = 0; // No registrado (rojo)
        } else if (_habits[index]['current'] < _habits[index]['goal']) {
          _habits[index]['days'][today] = 1; // Parcial (amarillo)
        }
      }
    });
  }

  void _toggleBooleanHabit(int index) {
    setState(() {
      _habits[index]['current'] = !_habits[index]['current'];

      // Actualizar el estado del día actual
      final today = DateTime.now().weekday % 7;
      _habits[index]['days'][today] = _habits[index]['current'] ? 2 : 0;
    });
  }

  void _showRegisterTimeDialog(int index) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

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
              onPressed: () {
                // Actualizar el tiempo del hábito
                final newTime =
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                setState(() {
                  _habits[index]['current'] = newTime;

                  // Actualizar el estado del día actual
                  final today = DateTime.now().weekday % 7;

                  // Determinar el estado basado en el progreso
                  if (hours > 0 || minutes > 0 || seconds > 0) {
                    _habits[index]['days'][today] =
                        1; // Al menos se registró algo
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _editHabit(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                HabitFormScreen(habit: _habits[index], isEditing: true),
      ),
    ).then((updatedHabit) {
      if (updatedHabit != null) {
        setState(() {
          _habits[index] = updatedHabit;
        });
      }
    });
  }

  void _deleteHabit(int index) {
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
              onPressed: () {
                setState(() {
                  _habits.removeAt(index);
                });
                Navigator.pop(context);
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
        child:
            _habits.isEmpty
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
                    final habitType = habit['type'] ?? 'count';

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
                                  Text(
                                    habit['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editHabit(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteHabit(index),
                                      ),
                                    ],
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
                                    _buildDayCircle('D', habit['days'][0]),
                                    _buildDayCircle('L', habit['days'][1]),
                                    _buildDayCircle('M', habit['days'][2]),
                                    _buildDayCircle('X', habit['days'][3]),
                                    _buildDayCircle('J', habit['days'][4]),
                                    _buildDayCircle('V', habit['days'][5]),
                                    _buildDayCircle('S', habit['days'][6]),
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
                                      '${habit['current']}/${habit['goal']}',
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
                                      '${habit['current']}/${habit['goal']}',
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
                                      habit['current']
                                          ? 'Completado'
                                          : 'Pendiente',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            habit['current']
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        habit['current']
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        color:
                                            habit['current']
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
        onPressed: () {
          // Navegar a la pantalla de creación de hábito
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HabitFormScreen()),
          ).then((newHabit) {
            if (newHabit != null) {
              setState(() {
                _habits.add(newHabit);
              });
            }
          });
        },
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
