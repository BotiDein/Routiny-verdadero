import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/habit_form_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late FirebaseService _firebaseService;
  final LocalStorageService _storageService = LocalStorageService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // 🔧 MEJORADO: Sistema de protección más robusto contra múltiples toques
  final Map<String, bool> _habitUpdating = {}; // Track por hábito individual
  final Map<String, DateTime> _lastUpdateTime =
      {}; // Tiempo de última actualización por hábito
  final Map<String, int> _lastStatus = {}; // Último estado por hábito

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _firebaseService = FirebaseService(userId);
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _firebaseService.getHabits().listen(
        (habits) {
          if (mounted) {
            setState(() {
              habits.sort((a, b) {
                final today = DateTime.now().weekday % 7;
                final aCompleted = a.days[today] == 2;
                final bCompleted = b.days[today] == 2;

                if (aCompleted && !bCompleted) return 1;
                if (!aCompleted && bCompleted) return -1;

                return 0;
              });

              _habits = habits;
              _isLoading = false;

              // 🔧 NUEVO: Inicializar estados de protección para cada hábito
              for (var habit in habits) {
                _habitUpdating[habit.id] = false;
                final today = DateTime.now().weekday % 7;
                _lastStatus[habit.id] = habit.days[today];
              }

              _syncWithLocalStorage(habits);
            });
          }
        },
        onError: (e) {
          _loadFromLocalStorage();
        },
      );
    } catch (e) {
      _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final habits = await _storageService.getHabits();

      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
          _hasError = false;

          // Inicializar estados de protección
          for (var habit in habits) {
            _habitUpdating[habit.id] = false;
            final today = DateTime.now().weekday % 7;
            _lastStatus[habit.id] = habit.days[today];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _habits = [];
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error al cargar hábitos: $e';
        });
      }
    }
  }

  Future<void> _syncWithLocalStorage(List<Habit> habits) async {
    try {
      await _storageService.saveHabits(habits);
    } catch (e) {
      print('Error al sincronizar con almacenamiento local: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(Habit habit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar hábito'),
          content: Text(
            '¿Estás seguro de que deseas eliminar el hábito "${habit.name}"?',
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
                Navigator.of(context).pop();
                _deleteHabit(habit);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    try {
      await _firebaseService.deleteHabit(habit.id);
      await _storageService.deleteHabit(habit.id);

      setState(() {
        _habits.removeWhere((h) => h.id == habit.id);
        // Limpiar estados de protección
        _habitUpdating.remove(habit.id);
        _lastUpdateTime.remove(habit.id);
        _lastStatus.remove(habit.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hábito eliminado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
      );
    }
  }

  // 🔧 ULTRA MEJORADO: Protección robusta contra múltiples toques
  Future<void> _updateHabitStatus(Habit habit, int status) async {
    final habitId = habit.id;
    final now = DateTime.now();

    // 1. Verificar si ya se está actualizando este hábito específico
    if (_habitUpdating[habitId] == true) {
      print('🚫 Hábito $habitId ya se está actualizando, ignorando toque');
      return;
    }

    // 2. Verificar si es el mismo estado que ya tiene
    final today = DateTime.now().weekday % 7;
    if (habit.days[today] == status) {
      print('🚫 Hábito $habitId ya tiene el estado $status, ignorando toque');
      return;
    }

    // 3. Verificar tiempo desde última actualización (mínimo 2 segundos)
    if (_lastUpdateTime[habitId] != null &&
        now.difference(_lastUpdateTime[habitId]!).inMilliseconds < 2000) {
      print(
        '🚫 Hábito $habitId actualizado muy recientemente, ignorando toque',
      );
      return;
    }

    // 4. Verificar si el estado cambió desde la última actualización conocida
    if (_lastStatus[habitId] != null && _lastStatus[habitId] == status) {
      print('🚫 Hábito $habitId ya procesó este estado, ignorando toque');
      return;
    }

    // Marcar como actualizando INMEDIATAMENTE
    setState(() {
      _habitUpdating[habitId] = true;
    });

    print('✅ Iniciando actualización de hábito $habitId a estado $status');

    try {
      final updatedDays = List<int>.from(habit.days);
      updatedDays[today] = status;

      final todayStr = _formatDate(DateTime.now());
      final updatedCompletedDates = Map<String, int>.from(habit.completedDates);

      if (status > 0) {
        updatedCompletedDates[todayStr] = status;
      } else {
        updatedCompletedDates.remove(todayStr);
      }

      final updatedHabit = habit.copyWith(
        days: updatedDays,
        completedDates: updatedCompletedDates,
      );

      // Actualizar en Firebase y almacenamiento local
      await _firebaseService.updateHabit(updatedHabit);
      await _storageService.updateHabit(updatedHabit);

      // Actualizar UI y estados de protección
      setState(() {
        final index = _habits.indexWhere((h) => h.id == habit.id);
        if (index != -1) {
          _habits[index] = updatedHabit;
        }
        _lastStatus[habitId] = status;
        _lastUpdateTime[habitId] = now;
      });

      // Mostrar mensaje de confirmación
      String statusText =
          status == 0
              ? "no completado"
              : (status == 1 ? "parcialmente completado" : "completado");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hábito marcado como $statusText'),
          duration: const Duration(seconds: 1),
        ),
      );

      print('✅ Hábito $habitId actualizado exitosamente a estado $status');
    } catch (e) {
      print('❌ Error al actualizar hábito $habitId: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      // Liberar el bloqueo después de un delay más largo
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _habitUpdating[habitId] = false;
          });
          print('🔓 Liberado bloqueo para hábito $habitId');
        }
      });
    }
  }

  void _showRegisterTimeDialog(Habit habit) {
    // Verificar si ya se está actualizando
    if (_habitUpdating[habit.id] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espera a que termine la actualización anterior'),
        ),
      );
      return;
    }

    String currentTime =
        habit.current is String ? habit.current as String : '00:00:00';
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
                height: 200,
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
                // Marcar como actualizando antes de procesar
                setState(() {
                  _habitUpdating[habit.id] = true;
                });

                try {
                  final newTime =
                      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                  int status = 0;
                  if (hours > 0 || minutes > 0 || seconds > 0) {
                    final goalTime =
                        habit.goal is String
                            ? habit.goal as String
                            : '00:00:00';

                    List<String> goalParts = goalTime.split(':');
                    int goalHours = int.tryParse(goalParts[0]) ?? 0;
                    int goalMinutes = int.tryParse(goalParts[1]) ?? 0;
                    int goalSeconds = int.tryParse(goalParts[2]) ?? 0;

                    int totalSeconds = hours * 3600 + minutes * 60 + seconds;
                    int goalTotalSeconds =
                        goalHours * 3600 + goalMinutes * 60 + goalSeconds;

                    if (totalSeconds >= goalTotalSeconds &&
                        goalTotalSeconds > 0) {
                      status = 2;
                    } else {
                      status = 1;
                    }
                  }

                  final updatedDays = List<int>.from(habit.days);
                  final today = DateTime.now().weekday % 7;
                  updatedDays[today] = status;

                  final todayStr = _formatDate(DateTime.now());
                  final updatedCompletedDates = Map<String, int>.from(
                    habit.completedDates,
                  );
                  if (status > 0) {
                    updatedCompletedDates[todayStr] = status;
                  } else {
                    updatedCompletedDates.remove(todayStr);
                  }

                  final updatedRegisteredTimes = Map<String, String>.from(
                    habit.registeredTimes,
                  );
                  updatedRegisteredTimes[todayStr] = newTime;

                  final updatedHabit = habit.copyWith(
                    current: newTime,
                    days: updatedDays,
                    completedDates: updatedCompletedDates,
                    registeredTimes: updatedRegisteredTimes,
                  );

                  await _firebaseService.updateHabit(updatedHabit);
                  await _storageService.updateHabit(updatedHabit);

                  setState(() {
                    final index = _habits.indexWhere((h) => h.id == habit.id);
                    if (index != -1) {
                      _habits[index] = updatedHabit;
                    }
                    _lastStatus[habit.id] = status;
                    _lastUpdateTime[habit.id] = DateTime.now();
                  });

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tiempo registrado correctamente'),
                    ),
                  );
                } catch (e) {
                  print('Error al guardar tiempo: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                  Navigator.of(context).pop();
                } finally {
                  // Liberar bloqueo
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (mounted) {
                      setState(() {
                        _habitUpdating[habit.id] = false;
                      });
                    }
                  });
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHabitForm({Habit? habit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                HabitFormScreen(habit: habit, isEditing: habit != null),
      ),
    );

    if (result != null && result is Habit) {
      try {
        if (habit != null) {
          await _firebaseService.updateHabit(result);
          await _storageService.updateHabit(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito actualizado correctamente')),
          );
        } else {
          await _firebaseService.addHabit(result);
          await _storageService.addHabit(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito creado correctamente')),
          );
        }

        _loadHabits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFE0FFFF),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
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
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No hay hábitos pendientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el botón + para añadir un hábito',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return _buildHabitCard(habit);
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0047AB),
        onPressed: () => _navigateToHabitForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final today = DateTime.now().weekday % 7;
    final isCompleted = habit.days[today] == 2;
    final isPartial = habit.days[today] == 1;
    final isUpdating = _habitUpdating[habit.id] ?? false;

    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isPartial) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }

    final todayStr = _formatDate(DateTime.now());
    final hasRegisteredTime = habit.registeredTimes.containsKey(todayStr);
    final registeredTime =
        hasRegisteredTime ? habit.registeredTimes[todayStr] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      color: const Color(0xFFB3E5FC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(habit.category).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(habit.category),
                    color: _getCategoryColor(habit.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (habit.description.isNotEmpty)
                        Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToHabitForm(habit: habit);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(habit);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF4A90E2)),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getHabitTypeText(habit),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getHabitGoalText(habit),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (habit.type == 'time' && registeredTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Registrado hoy: $registeredTime',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 🔧 ULTRA MEJORADO: Botones con protección visual y funcional
                if (habit.type == 'time')
                  ElevatedButton.icon(
                    onPressed:
                        isUpdating
                            ? null
                            : () => _showRegisterTimeDialog(habit),
                    icon:
                        isUpdating
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.timer),
                    label: Text(isUpdating ? 'Guardando...' : 'Registrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isUpdating ? Colors.grey : const Color(0xFF0047AB),
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  // 🔧 ULTRA MEJORADO: Botones con protección completa
                  Row(
                    children: [
                      // Botón de no completado
                      _buildStatusButton(
                        habit: habit,
                        targetStatus: 0,
                        currentStatus: habit.days[today],
                        icon: Icons.close,
                        color: Colors.grey,
                        isUpdating: isUpdating,
                      ),
                      const SizedBox(width: 8),

                      // Botón de parcialmente completado
                      _buildStatusButton(
                        habit: habit,
                        targetStatus: 1,
                        currentStatus: habit.days[today],
                        icon: Icons.remove,
                        color: Colors.orange,
                        isUpdating: isUpdating,
                      ),
                      const SizedBox(width: 8),

                      // Botón de completado
                      _buildStatusButton(
                        habit: habit,
                        targetStatus: 2,
                        currentStatus: habit.days[today],
                        icon: Icons.check,
                        color: Colors.green,
                        isUpdating: isUpdating,
                        showProgress: true,
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildDayIndicators(habit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 NUEVO: Widget para botones de estado con protección completa
  Widget _buildStatusButton({
    required Habit habit,
    required int targetStatus,
    required int currentStatus,
    required IconData icon,
    required Color color,
    required bool isUpdating,
    bool showProgress = false,
  }) {
    final isActive = currentStatus == targetStatus;
    final isDisabled = isUpdating || isActive;

    return GestureDetector(
      onTap: isDisabled ? null : () => _updateHabitStatus(habit, targetStatus),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : color.withOpacity(0.2),
            border:
                isUpdating && isActive
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
          ),
          child:
              isUpdating && isActive && showProgress
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(
                    icon,
                    color: isActive ? Colors.white : color,
                    size: 20,
                  ),
        ),
      ),
    );
  }

  List<Widget> _buildDayIndicators(Habit habit) {
    final days = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    final today = DateTime.now().weekday % 7;

    return List.generate(7, (index) {
      Color color;
      final status = habit.days[index];

      if (status == 2) {
        color = Colors.green;
      } else if (status == 1) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }

      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border:
              index == today ? Border.all(color: Colors.black, width: 2) : null,
        ),
        child: Center(
          child: Text(
            days[index],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ejercicio':
        return Icons.fitness_center;
      case 'Salud':
        return Icons.favorite;
      case 'Educación':
        return Icons.school;
      case 'Trabajo':
        return Icons.work;
      case 'Personal':
        return Icons.person;
      case 'Finanzas':
        return Icons.attach_money;
      case 'Hobbies':
        return Icons.palette;
      default:
        return Icons.spa;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ejercicio':
        return Colors.orange;
      case 'Salud':
        return Colors.red;
      case 'Educación':
        return Colors.blue;
      case 'Trabajo':
        return Colors.brown;
      case 'Personal':
        return Colors.purple;
      case 'Finanzas':
        return Colors.green;
      case 'Hobbies':
        return Colors.pink;
      default:
        return Colors.teal;
    }
  }

  String _getHabitTypeText(Habit habit) {
    if (habit.type == 'time') {
      return 'Tiempo';
    } else if (habit.type == 'boolean') {
      return 'Completar';
    } else {
      return 'Conteo';
    }
  }

  String _getHabitGoalText(Habit habit) {
    if (habit.type == 'time') {
      if (habit.option == 'Sin objetivo') {
        return 'Sin objetivo de tiempo';
      }
      return '${habit.option} ${habit.goal}';
    } else if (habit.type == 'boolean') {
      return 'Marcar como completado';
    } else {
      if (habit.option == 'Sin objetivo') {
        return 'Sin objetivo de conteo';
      }
      return '${habit.option} ${habit.goal} ${habit.goal == 1 ? 'vez' : 'veces'}';
    }
  }
}
