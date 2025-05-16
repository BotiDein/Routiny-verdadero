import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hobby.dart';
import '../services/local_storage_service.dart';
import 'hobby_form_screen.dart';
import '../services/firebase_service.dart';

class HobbyDetailScreen extends StatefulWidget {
  final Hobby hobby;

  const HobbyDetailScreen({super.key, required this.hobby});

  @override
  State<HobbyDetailScreen> createState() => _HobbyDetailScreenState();
}

class _HobbyDetailScreenState extends State<HobbyDetailScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  String _totalTime = '00:00:00';
  String _weeklyGoal = '05:00:00';
  bool _goalCompleted = false;
  bool _goalExceeded = false;

  // Lista de tiempos registrados
  List<Map<String, dynamic>> _registeredTimes = [];

  // Días con actividad (0 = domingo, 6 = sábado)
  List<int> _activeDays = []; // Inicializada como vacía

  // Actualiza solo el hobby que acabas de modificar
  Future<void> _syncWithFirebase() async {
    final firebaseService = FirebaseService();
    // En vez de traer todos y subirlos, sube solo el actualizado:
    final updatedHobby = Hobby(
      id: widget.hobby.id,
      name: widget.hobby.name,
      icon: widget.hobby.icon,
      time: _totalTime,
      weeklyGoal: _weeklyGoal,
      registeredTimes: _registeredTimes,
      activeDays: _activeDays,
    );
    await firebaseService.saveSingleUserHobby(updatedHobby);
  }

  @override
  void initState() {
    super.initState();
    // Inicializar con los datos del hobby
    _weeklyGoal = widget.hobby.weeklyGoal;
    _registeredTimes = widget.hobby.registeredTimes;
    _activeDays = widget.hobby.activeDays;
    _totalTime = widget.hobby.time;
    
    _calculateTotalTime();
    _checkGoalCompletion();
  }

  void _startTimer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopwatchScreen(hobby: widget.hobby),
      ),
    ).then((result) async {
      // Procesar el resultado cuando vuelva de la pantalla del cronómetro
      if (result != null && result is String) {
        // Convertir el formato del cronómetro (MM:SS.CC) a formato de tiempo (HH:MM:SS)
        final parts = result.split(':');
        if (parts.length == 2) {
          final minutesPart = parts[0];
          final secondsPart = parts[1].split('.')[0];
          final formattedTime = '00:$minutesPart:$secondsPart';

          // 1. Actualizar datos locales
          _registeredTimes.add({
            'date': DateTime.now(),
            'time': formattedTime,
          });

          final today = DateTime.now().weekday % 7;
          if (!_activeDays.contains(today)) {
            _activeDays.add(today);
          }

          _calculateTotalTime();
          _checkGoalCompletion();

          // 2. Guardar cambios
          await _updateAndSaveHobby(); // Esto ya incluye guardar local y Firebase

          // 3. Actualizar UI (si es necesario)
          setState(() {});
        }
      }
    });
  }

  void _showRegisterTimeDialog() {
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
                onPressed: () async {
                  // 1. Construir el nuevo registro de tiempo
                  final newTime =
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                  // 2. Actualizar datos locales
                  _registeredTimes.add({
                    'date': DateTime.now(),
                    'time': newTime,
                  });

                  final today = DateTime.now().weekday % 7;
                  if (!_activeDays.contains(today)) {
                    _activeDays.add(today);
                  }

                  _calculateTotalTime();
                  _checkGoalCompletion();

                  // 3. Guardar en storage local y en Firebase
                  await _updateAndSaveHobby(); // <- Usa await para esperar que se complete

                  // 4. Actualizar UI
                  setState(() {});

                  // 5. Cerrar el diálogo
                  Navigator.of(context).pop();
                },
                child: const Text('Guardar'),
              ),

          ],
        );
      },
    );
  }

// Actualizar el hobby y guardarlo
  Future<void> _updateAndSaveHobby() async {
    final updatedHobby = Hobby(
      id: widget.hobby.id,
      name: widget.hobby.name,
      icon: widget.hobby.icon,
      time: _totalTime,
      weeklyGoal: _weeklyGoal,
      registeredTimes: _registeredTimes,
      activeDays: _activeDays,
    );
    
    // 1) Espera a que se actualice localmente
    await _storageService.updateHobby(updatedHobby);
    
    // 2) Luego sincroniza con Firebase
    await _syncWithFirebase();
  }

  // Convertir tiempo en formato HH:MM:SS a segundos
  int _timeToSeconds(String time) {
    final parts = time.split(':');
    if (parts.length != 3) return 0;
    
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    
    return hours * 3600 + minutes * 60 + seconds;
  }
  
  // Convertir segundos a formato HH:MM:SS
  String _secondsToTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _calculateTotalTime() {
    int totalSeconds = 0;
    
    for (var timeEntry in _registeredTimes) {
      totalSeconds += _timeToSeconds(timeEntry['time']);
    }
    
    setState(() {
      _totalTime = _secondsToTime(totalSeconds);
    });
  }

  void _checkGoalCompletion() {
    final totalSeconds = _timeToSeconds(_totalTime);
    final goalSeconds = _timeToSeconds(_weeklyGoal);
    
    setState(() {
      _goalCompleted = totalSeconds >= goalSeconds;
      
      // Verificar si se excedió la meta por 5 horas o más
      final fiveHoursInSeconds = 5 * 3600; // 5 horas en segundos
      _goalExceeded = totalSeconds >= (goalSeconds + fiveHoursInSeconds);
    });
  }

  void _editHobby() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HobbyFormScreen(
          hobby: {
            'id': widget.hobby.id,
            'name': widget.hobby.name,
            'icon': widget.hobby.icon,
            'time': widget.hobby.time,
            'weeklyGoal': widget.hobby.weeklyGoal,
            'registeredTimes': widget.hobby.registeredTimes,
            'activeDays': widget.hobby.activeDays,
          },
          isEditing: true,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Actualizar el hobby con los nuevos datos
        setState(() {
          _weeklyGoal = result['weeklyGoal'] ?? _weeklyGoal;
          
          // Verificar si se cumplió la meta con el nuevo objetivo
          _checkGoalCompletion();
          
          // Actualizar el hobby y guardarlo
          final updatedHobby = Hobby(
            id: widget.hobby.id,
            name: result['name'] ?? widget.hobby.name,
            icon: result['icon'] ?? widget.hobby.icon,
            time: _totalTime,
            weeklyGoal: _weeklyGoal,
            registeredTimes: _registeredTimes,
            activeDays: _activeDays,
          );
          
          _storageService.updateHobby(updatedHobby);
          
          // Actualizar la referencia al hobby
          widget.hobby.time = _totalTime;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hobby actualizado')),
        );
      }
    });
  }

  void _deleteHobby() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar hobby'),
          content: const Text('¿Estás seguro de que deseas eliminar este hobby?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de confirmación
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // 1. Eliminar localmente
                  await _storageService.deleteHobby(widget.hobby.id);

                  // 2. Eliminar de Firebase
                  final firebaseService = FirebaseService();
                  await firebaseService.deleteUserHobby(widget.hobby.id);

                  // 3. Cerrar ambos contextos
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pop(true); // Retorna a la pantalla anterior

                } catch (e) {
                  Navigator.of(context).pop(); // Cierra el diálogo si falla
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
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
    return WillPopScope(
      // Interceptar el botón de retroceso para devolver el hobby actualizado
      onWillPop: () async {
        final updatedHobby = Hobby(
          id: widget.hobby.id,
          name: widget.hobby.name,
          icon: widget.hobby.icon,
          time: _totalTime,
          weeklyGoal: _weeklyGoal,
          registeredTimes: _registeredTimes,
          activeDays: _activeDays,
        );
        Navigator.pop(context, updatedHobby);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A90E2),
          title: const Text(
            'Detalles del Hobby',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              final updatedHobby = Hobby(
                id: widget.hobby.id,
                name: widget.hobby.name,
                icon: widget.hobby.icon,
                time: _totalTime,
                weeklyGoal: _weeklyGoal,
                registeredTimes: _registeredTimes,
                activeDays: _activeDays,
              );
              Navigator.of(context).pop(updatedHobby);
            },
          ),
        ),
        body: Container(
          color: const Color(0xFFD6F9F0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                widget.hobby.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tiempo total registrado',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Text(
                _totalTime,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Meta Semanal',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Text(
                _weeklyGoal,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _goalCompleted ? 'Cumplido' : 'No cumplido',
                    style: TextStyle(
                      fontSize: 16,
                      color: _goalCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _goalCompleted ? Icons.check_circle : Icons.cancel,
                    color: _goalCompleted ? Colors.green : Colors.red,
                  ),
                ],
              ),
              
              // Aviso de exceso de meta
              if (_goalExceeded)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Atención! Has excedido tu meta semanal por más de 5 horas.',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              // Días con actividad
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Días con actividad',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDayCircle('D', 0),
                        _buildDayCircle('L', 1),
                        _buildDayCircle('M', 2),
                        _buildDayCircle('X', 3),
                        _buildDayCircle('J', 4),
                        _buildDayCircle('V', 5),
                        _buildDayCircle('S', 6),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tiempos registrados
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tiempos registrados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _registeredTimes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay tiempos registrados.\nUtiliza los botones de abajo para registrar tiempo.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _registeredTimes.length,
                                itemBuilder: (context, index) {
                                  final dateFormat = DateFormat('dd MMMM yyyy', 'es');
                                  final formattedDate = dateFormat.format(
                                    _registeredTimes[index]['date'],
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Divider(
                                                    color: Colors.blue,
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.alarm, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _registeredTimes[index]['time'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botones inferiores
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Iniciar Cronómetro',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showRegisterTimeDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Registrar Tiempo',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _deleteHobby,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _editHobby,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Editar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDayCircle(String day, int dayIndex) {
    final isActive = _activeDays.contains(dayIndex);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.transparent,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// La clase StopwatchScreen permanece igual, pero necesita ser actualizada para trabajar con el modelo Hobby

// Pantalla del cronómetro integrada en el mismo archivo
class StopwatchScreen extends StatefulWidget {
  final Hobby hobby;

  const StopwatchScreen({super.key, required this.hobby});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  // Estados del cronómetro
  bool _isRunning = false;
  bool _isPaused = false;

  // Variables para el cronómetro
  Stopwatch _stopwatch = Stopwatch();
  String _elapsedTime = "00:00.00";
  Timer? _timer;

  // Lista de checkpoints
  final List<String> _checkpoints = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Iniciar el cronómetro
  void _startStopwatch() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _stopwatch.start();

      // Actualizar el tiempo cada 10 milisegundos
      _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (_stopwatch.isRunning) {
          setState(() {
            _elapsedTime = _formatTime(_stopwatch.elapsedMilliseconds);
          });
        }
      });
    });
  }

  // Pausar el cronómetro
  void _pauseStopwatch() {
    setState(() {
      _isPaused = true;
      _stopwatch.stop();
    });
  }

  // Reanudar el cronómetro
  void _resumeStopwatch() {
    setState(() {
      _isPaused = false;
      _stopwatch.start();
    });
  }

  // Detener y reiniciar el cronómetro
  void _resetStopwatch() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _stopwatch.stop();
      _stopwatch.reset();
      _elapsedTime = "00:00.00";
      _checkpoints.clear();
      _timer?.cancel();
    });
  }

  // Añadir un checkpoint
  void _addCheckpoint() {
    setState(() {
      _checkpoints.insert(
        0,
        _elapsedTime,
      ); // Insertar al inicio para mostrar el más reciente primero
    });
  }

  // Formatear el tiempo en milisegundos a formato MM:SS.CC
  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds ~/ 10) % 100;
    int seconds = (milliseconds ~/ 1000) % 60;
    int minutes = (milliseconds ~/ 60000) % 60;

    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundreds.toString().padLeft(2, '0')}";
  }

  // Guardar el tiempo total y volver a la pantalla anterior
  void _saveAndGoBack() {
    // Aquí podrías implementar la lógica para guardar el tiempo total
    Navigator.pop(context, _elapsedTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: Text(
          _isRunning
              ? (_isPaused ? "Cronómetro pausado" : "Cronómetro empezado")
              : "Cronómetro sin empezar",
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () {
            // Preguntar si desea guardar el tiempo antes de salir
            if (_isRunning) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('¿Guardar tiempo?'),
                      content: const Text(
                        '¿Deseas guardar el tiempo registrado?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar diálogo
                            Navigator.pop(context); // Volver sin guardar
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Cerrar diálogo
                            _saveAndGoBack(); // Guardar y volver
                          },
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        color: const Color(0xFFD6F9F0),
        child: Column(
          children: [
            // Tiempo del cronómetro
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _elapsedTime,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
            ),

            // Botones de control
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning) ...[
                    // Botón de inicio
                    _buildCircleButton(
                      onPressed: _startStopwatch,
                      icon: Icons.play_arrow,
                      color: Colors.blue,
                    ),
                  ] else if (!_isPaused) ...[
                    // Botón de checkpoint
                    _buildCircleButton(
                      onPressed: _addCheckpoint,
                      icon: Icons.flag,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 40),
                    // Botón de pausa
                    _buildCircleButton(
                      onPressed: _pauseStopwatch,
                      icon: Icons.pause,
                      color: Colors.blue,
                    ),
                  ] else ...[
                    // Botón de detener
                    _buildCircleButton(
                      onPressed: _resetStopwatch,
                      icon: Icons.stop,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 40),
                    // Botón de reanudar
                    _buildCircleButton(
                      onPressed: _resumeStopwatch,
                      icon: Icons.play_arrow,
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
            ),

            // Lista de checkpoints
            if (_checkpoints.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Checkpoints',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: _checkpoints.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        'Checkpoint ${index + 1}: ${_checkpoints[index]}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Botón para guardar el tiempo total
            if (_isRunning || _elapsedTime != "00:00.00") ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _saveAndGoBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Guardar tiempo total',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 30),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}