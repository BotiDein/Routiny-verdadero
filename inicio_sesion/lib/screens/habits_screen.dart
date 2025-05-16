import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/habit_form_screen.dart';
import 'dart:math' as math;

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
      // Primero intentamos cargar desde Firebase
      _firebaseService.getHabits().listen((habits) {
        if (mounted) {
          setState(() {
            // Ordenar hábitos: primero los no completados, luego los completados
            habits.sort((a, b) {
              // Verificar si el hábito está completado para hoy
              final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
              final aCompleted = a.days[today] == 2;
              final bCompleted = b.days[today] == 2;
              
              // Mover los completados al final
              if (aCompleted && !bCompleted) return 1;
              if (!aCompleted && bCompleted) return -1;
              
              // Si ambos tienen el mismo estado, mantener el orden original
              return 0;
            });
            
            _habits = habits;
            _isLoading = false;
            
            // Sincronizar con almacenamiento local
            _syncWithLocalStorage(habits);
          });
        }
      }, onError: (e) {
        // Si hay error en Firebase, intentamos cargar desde almacenamiento local
        _loadFromLocalStorage();
      });
    } catch (e) {
      // Si hay cualquier error, intentamos cargar desde almacenamiento local
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

// Modificar los métodos para usar fechas específicas en lugar de días de la semana

// Modificar el método _incrementHabit
// void _incrementHabit(int index) async {
//   if (index < 0 || index >= _habits.length) return;
  
//   try {
//     final habit = _habits[index];
    
//     if (habit.type == 'count') {
//       final current = habit.current is int ? habit.current as int : 0;
//       final goal = habit.goal is int ? habit.goal as int : 0;
      
//       if (goal == 0 || current < goal) {
//         // Crear una copia del hábito con el valor actualizado
//         final updatedDays = List<int>.from(habit.days);
//         final today = DateTime.now().weekday % 7;
        
//         // Actualizar el estado del día actual
//         if (goal > 0 && current + 1 >= goal) {
//           updatedDays[today] = 2; // Completado
//         } else {
//           updatedDays[today] = 1; // Parcial
//         }
        
//         // Actualizar el mapa de fechas específicas
//         final todayStr = _formatDate(DateTime.now());
//         final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
//         updatedCompletedDates[todayStr] = goal > 0 && current + 1 >= goal ? 2 : 1;
        
//         final updatedHabit = habit.copyWith(
//           current: current + 1,
//           days: updatedDays,
//           completedDates: updatedCompletedDates,
//         );
        
//         // Actualizar la UI primero
//         setState(() {
//           _habits[index] = updatedHabit;
//         });
        
//         // Depurar fechas completadas
//         _debugPrintCompletedDates(updatedHabit);
        
//         // Guardar en almacenamiento local
//         await _storageService.updateHabit(updatedHabit);
//       }
//     }
//   } catch (e) {
//     print('Error al incrementar hábito: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error al actualizar: $e')),
//       );
//     }
//   }
// }

// // Modificar el método _decrementHabit
// void _decrementHabit(int index) async {
//   if (index < 0 || index >= _habits.length) return;
  
//   try {
//     final habit = _habits[index];
    
//     if (habit.type == 'count') {
//       final current = habit.current is int ? habit.current as int : 0;
      
//       if (current > 0) {
//         // Crear una copia del hábito con el valor actualizado
//         final updatedDays = List<int>.from(habit.days);
//         final today = DateTime.now().weekday % 7;
//         final goal = habit.goal is int ? habit.goal as int : 0;
        
//         // Actualizar el estado del día actual
//         if (current - 1 <= 0) {
//           updatedDays[today] = 0; // No registrado
//         } else if (goal > 0 && current - 1 < goal) {
//           updatedDays[today] = 1; // Parcial
//         }
        
//         // Actualizar el mapa de fechas específicas
//         final todayStr = _formatDate(DateTime.now());
//         final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
//         if (current - 1 <= 0) {
//           updatedCompletedDates.remove(todayStr); // Eliminar si no hay progreso
//         } else {
//           updatedCompletedDates[todayStr] = goal > 0 && current - 1 < goal ? 1 : 2;
//         }
        
//         final updatedHabit = habit.copyWith(
//           current: current - 1,
//           days: updatedDays,
//           completedDates: updatedCompletedDates,
//         );
        
//         // Actualizar la UI primero
//         setState(() {
//           _habits[index] = updatedHabit;
//         });
        
//         // Guardar en almacenamiento local
//         await _storageService.updateHabit(updatedHabit);
//       }
//     }
//   } catch (e) {
//     print('Error al decrementar hábito: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error al actualizar: $e')),
//       );
//     }
//   }
// }

// // Modificar el método _toggleBooleanHabit
// void _toggleBooleanHabit(int index) async {
//   if (index < 0 || index >= _habits.length) return;
  
//   try {
//     final habit = _habits[index];
    
//     if (habit.type == 'boolean') {
//       final current = habit.current is bool ? habit.current as bool : false;
      
//       // Crear una copia del hábito con el valor actualizado
//       final updatedDays = List<int>.from(habit.days);
//       final today = DateTime.now().weekday % 7;
      
//       // Actualizar el estado del día actual
//       updatedDays[today] = !current ? 2 : 0; // 2 = completado, 0 = no registrado
      
//       // Actualizar el mapa de fechas específicas
//       final todayStr = _formatDate(DateTime.now());
//       final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
//       if (!current) {
//         updatedCompletedDates[todayStr] = 2; // Completado
//       } else {
//         updatedCompletedDates.remove(todayStr); // Eliminar si se desmarca
//       }
      
//       final updatedHabit = habit.copyWith(
//         current: !current,
//         days: updatedDays,
//         completedDates: updatedCompletedDates,
//       );
      
//       // Actualizar la UI primero
//       setState(() {
//         _habits[index] = updatedHabit;
//       });
      
//       // Guardar en almacenamiento local
//       await _storageService.updateHabit(updatedHabit);
//     }
//   } catch (e) {
//     print('Error al cambiar hábito booleano: $e');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error al actualizar: $e')),
//       );
//     }
//   }
// }

// // Modificar el método _showRegisterTimeDialog
// void _showRegisterTimeDialog(int index) {
//   if (index < 0 || index >= _habits.length) return;
  
//   final habit = _habits[index];
//   String currentTime = habit.current is String ? habit.current as String : '00:00:00';
  
//   // Extraer horas, minutos y segundos del tiempo actual
//   List<String> timeParts = currentTime.split(':');
//   int hours = int.tryParse(timeParts[0]) ?? 0;
//   int minutes = int.tryParse(timeParts[1]) ?? 0;
//   int seconds = int.tryParse(timeParts[2]) ?? 0;

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Registrar Tiempo'),
//         content: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return SizedBox(
//               height: 180,
//               child: Column(
//                 children: [
//                   const Text('Selecciona el tiempo a registrar:'),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       // Horas
//                       Column(
//                         children: [
//                           const Text('Horas'),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_up),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (hours < 23) hours++;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                           Text(
//                             hours.toString().padLeft(2, '0'),
//                             style: const TextStyle(fontSize: 24),
//                           ),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_down),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (hours > 0) hours--;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       // Minutos
//                       Column(
//                         children: [
//                           const Text('Minutos'),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_up),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (minutes < 59) minutes++;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                           Text(
//                             minutes.toString().padLeft(2, '0'),
//                             style: const TextStyle(fontSize: 24),
//                           ),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_down),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (minutes > 0) minutes--;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       // Segundos
//                       Column(
//                         children: [
//                           const Text('Segundos'),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_up),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (seconds < 59) seconds++;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                           Text(
//                             seconds.toString().padLeft(2, '0'),
//                             style: const TextStyle(fontSize: 24),
//                           ),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.arrow_drop_down),
//                                 onPressed: () {
//                                   setState(() {
//                                     if (seconds > 0) seconds--;
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 // Actualizar el tiempo del hábito
//                 final newTime =
//                     '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                
//                 // Crear una copia del hábito con el valor actualizado
//                 final updatedDays = List<int>.from(habit.days);
//                 final today = DateTime.now().weekday % 7;
//                 final goalTime = habit.goal is String ? habit.goal as String : '00:00:00';
                
//                 // Determinar el estado basado en el progreso
//                 int status = 0;
//                 if (hours > 0 || minutes > 0 || seconds > 0) {
//                   // Comparar con el objetivo
//                   List<String> goalParts = goalTime.split(':');
//                   int goalHours = int.tryParse(goalParts[0]) ?? 0;
//                   int goalMinutes = int.tryParse(goalParts[1]) ?? 0;
//                   int goalSeconds = int.tryParse(goalParts[2]) ?? 0;
                  
//                   int totalSeconds = hours * 3600 + minutes * 60 + seconds;
//                   int goalTotalSeconds = goalHours * 3600 + goalMinutes * 60 + goalSeconds;
                  
//                   if (totalSeconds >= goalTotalSeconds && goalTotalSeconds > 0) {
//                     status = 2; // Completado
//                   } else {
//                     status = 1; // Parcial
//                   }
//                 }
                
//                 updatedDays[today] = status;
                
//                 // Actualizar el mapa de fechas específicas
//                 final todayStr = _formatDate(DateTime.now());
//                 final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
//                 if (status > 0) {
//                   updatedCompletedDates[todayStr] = status;
//                 } else {
//                   updatedCompletedDates.remove(todayStr);
//                 }
                
//                 final updatedHabit = habit.copyWith(
//                   current: newTime,
//                   days: updatedDays,
//                   completedDates: updatedCompletedDates,
//                 );
                
//                 // Actualizar la UI primero
//                 setState(() {
//                   _habits[index] = updatedHabit;
//                 });
                
//                 // Guardar en almacenamiento local
//                 await _storageService.updateHabit(updatedHabit);
                
//                 Navigator.of(context).pop();
//               } catch (e) {
//                 print('Error al guardar tiempo: $e');
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Error al guardar: $e')),
//                 );
//                 Navigator.of(context).pop();
//               }
//             },
//             child: const Text('Guardar'),
//           ),
//         ],
//       );
//     },
//   );
// }

// Asegurémonos de que estamos guardando correctamente las fechas en el formato adecuado
// Modificar el método _formatDate para asegurarnos de que el formato sea correcto

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// También vamos a añadir un método de depuración para verificar las fechas guardadas
// Añadir este método después de _formatDate

void _showDeleteConfirmation(Habit habit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar hábito'),
          content: Text('¿Estás seguro de que deseas eliminar el hábito "${habit.name}"?'),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    try {
      // Eliminar de Firebase y almacenamiento local
      await _firebaseService.deleteHabit(habit.id);
      await _storageService.deleteHabit(habit.id);
      
      // Actualizar UI
      setState(() {
        _habits.removeWhere((h) => h.id == habit.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hábito eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateHabitStatus(Habit habit, int status) async {
    try {
      final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
      final updatedDays = List<int>.from(habit.days);
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
        days: updatedDays,
        completedDates: updatedCompletedDates,
      );
      
      // Actualizar en Firebase y almacenamiento local
      await _firebaseService.updateHabit(updatedHabit);
      await _storageService.updateHabit(updatedHabit);
      
      // Actualizar UI
      setState(() {
        final index = _habits.indexWhere((h) => h.id == habit.id);
        if (index != -1) {
          _habits[index] = updatedHabit;
        }
      });
      
      // Mostrar mensaje de confirmación
      String statusText = status == 0 ? "no completado" : (status == 1 ? "parcialmente completado" : "completado");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hábito marcado como $statusText')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showRegisterTimeDialog(Habit habit) {
    // Extraer tiempo actual
    String currentTime = habit.current is String ? habit.current as String : '00:00:00';
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
                  final newTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                  
                  // Determinar el estado basado en el progreso
                  int status = 0;
                  if (hours > 0 || minutes > 0 || seconds > 0) {
                    final goalTime = habit.goal is String ? habit.goal as String : '00:00:00';
                    
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
                  
                  // Actualizar el mapa de días
                  final updatedDays = List<int>.from(habit.days);
                  final today = DateTime.now().weekday % 7;
                  updatedDays[today] = status;
                  
                  // Actualizar el mapa de fechas específicas
                  final todayStr = _formatDate(DateTime.now());
                  final updatedCompletedDates = Map<String, int>.from(habit.completedDates);
                  if (status > 0) {
                    updatedCompletedDates[todayStr] = status;
                  } else {
                    updatedCompletedDates.remove(todayStr);
                  }
                  
                  // Actualizar el mapa de tiempos registrados
                  final updatedRegisteredTimes = Map<String, String>.from(habit.registeredTimes);
                  updatedRegisteredTimes[todayStr] = newTime;
                  
                  final updatedHabit = habit.copyWith(
                    current: newTime,
                    days: updatedDays,
                    completedDates: updatedCompletedDates,
                    registeredTimes: updatedRegisteredTimes,
                  );
                  
                  // Actualizar en Firebase y almacenamiento local
                  await _firebaseService.updateHabit(updatedHabit);
                  await _storageService.updateHabit(updatedHabit);
                  
                  // Actualizar UI
                  setState(() {
                    final index = _habits.indexWhere((h) => h.id == habit.id);
                    if (index != -1) {
                      _habits[index] = updatedHabit;
                    }
                  });
                  
                  Navigator.of(context).pop();
                  
                  // Mostrar mensaje de confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tiempo registrado correctamente')),
                  );
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

// También vamos a añadir un método de depuración para verificar las fechas guardadas
// Añadir este método después de _formatDate

// void _debugPrintCompletedDates(Habit habit) {
//   print('Hábito: ${habit.name}');
//   print('Fechas completadas:');
//   habit.completedDates.forEach((date, status) {
//     print('  $date: $status');
//   });
// }

  void _navigateToHabitForm({Habit? habit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitFormScreen(
          habit: habit,
          isEditing: habit != null,
        ),
      ),
    );

    if (result != null && result is Habit) {
      try {
        if (habit != null) {
          // Actualizar hábito existente
          await _firebaseService.updateHabit(result);
          await _storageService.updateHabit(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito actualizado correctamente')),
          );
        } else {
          // Añadir nuevo hábito
          await _firebaseService.addHabit(result);
          await _storageService.addHabit(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito creado correctamente')),
          );
        }
        
        // Recargar hábitos
        _loadHabits();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFE0FFFF), // Fondo azul claro
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.spa,
                              size: 80,
                              color: Colors.grey,
                            ),
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
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
        backgroundColor: const Color(0xFF0047AB), // Azul oscuro
        onPressed: () => _navigateToHabitForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
    final isCompleted = habit.days[today] == 2;
    final isPartial = habit.days[today] == 1;
    
    // Determinar el color según el estado
    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isPartial) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.grey;
    }
    
    // Verificar si hay tiempo registrado para hoy
    final todayStr = _formatDate(DateTime.now());
    final hasRegisteredTime = habit.registeredTimes.containsKey(todayStr);
    final registeredTime = hasRegisteredTime ? habit.registeredTimes[todayStr] : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: const Color(0xFFB3E5FC), // Color azul claro para las tarjetas
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de categoría
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
                
                // Título y descripción
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
                
                // Menú de opciones
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToHabitForm(habit: habit);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(habit);
                    }
                  },
                  itemBuilder: (context) => [
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
            
            // Progreso y detalles
            Row(
              children: [
                // Tipo de hábito y objetivo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getHabitTypeText(habit),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getHabitGoalText(habit),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Mostrar tiempo registrado si existe
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
                
                // Botones según el tipo de hábito
                if (habit.type == 'time')
                  ElevatedButton.icon(
                    onPressed: () => _showRegisterTimeDialog(habit),
                    icon: const Icon(Icons.timer),
                    label: const Text('Registrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047AB), // Azul oscuro
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  // Botones de estado para hábitos booleanos
                  Row(
                    children: [
                      // Botón de no completado
                      GestureDetector(
                        onTap: () => _updateHabitStatus(habit, 0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: habit.days[today] == 0 
                                ? Colors.grey 
                                : Colors.grey.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.close,
                            color: habit.days[today] == 0 
                                ? Colors.white 
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Botón de parcialmente completado
                      GestureDetector(
                        onTap: () => _updateHabitStatus(habit, 1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: habit.days[today] == 1 
                                ? Colors.orange 
                                : Colors.orange.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: habit.days[today] == 1 
                                ? Colors.white 
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Botón de completado
                      GestureDetector(
                        onTap: () => _updateHabitStatus(habit, 2),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: habit.days[today] == 2 
                                ? Colors.green 
                                : Colors.green.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.check,
                            color: habit.days[today] == 2 
                                ? Colors.white 
                                : Colors.green,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Días de la semana
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

  List<Widget> _buildDayIndicators(Habit habit) {
    final days = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    final today = DateTime.now().weekday % 7; // 0-6 (0 = domingo)
    
    return List.generate(7, (index) {
      // Determinar el color según el estado
      Color color;
      final status = habit.days[index];
      
      if (status == 2) {
        color = Colors.green; // Completado
      } else if (status == 1) {
        color = Colors.orange; // Parcial
      } else {
        color = Colors.red; // No completado
      }
      
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: index == today ? Border.all(color: Colors.black, width: 2) : null,
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
