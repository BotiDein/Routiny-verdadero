import 'package:flutter/material.dart';
import '../services/notification_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  
  bool _notificationsEnabled = true;
  bool _taskNotificationsEnabled = true;
  bool _habitNotificationsEnabled = true;
  bool _streakNotificationsEnabled = true;
  bool _hobbyNotificationsEnabled = true;
  bool _isLoading = true;
  
  late double screenWidth;
  late double screenHeight;
  
  double scaleWidth(double value) => value * screenWidth / 720;
  double scaleHeight(double value) => value * screenHeight / 1280;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    _notificationsEnabled = await _notificationManager.areNotificationsEnabled();
    _taskNotificationsEnabled = await _notificationManager.areTaskNotificationsEnabled();
    _habitNotificationsEnabled = await _notificationManager.areHabitNotificationsEnabled();
    _streakNotificationsEnabled = await _notificationManager.areStreakNotificationsEnabled();
    _hobbyNotificationsEnabled = await _notificationManager.areHobbyNotificationsEnabled();
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleFontSize = screenWidth * 0.06;
    final optionFontSize = screenWidth * 0.045;
    final iconSize = screenWidth * 0.06;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: scaleWidth(30),
                vertical: scaleHeight(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección principal de notificaciones
                  _buildMainSwitch(optionFontSize),
                  
                  SizedBox(height: scaleHeight(30)),
                  
                  // Secciones específicas (solo habilitadas si las notificaciones generales están activas)
                  _buildNotificationSection(
                    'Notificaciones de Tareas',
                    'Recibe alertas 5 minutos antes de cada tarea programada',
                    _taskNotificationsEnabled,
                    _notificationsEnabled,
                    optionFontSize,
                    (value) async {
                      if (_notificationsEnabled) {
                        await _notificationManager.setTaskNotificationsEnabled(value);
                        setState(() {
                          _taskNotificationsEnabled = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: scaleHeight(20)),
                  
                  _buildNotificationSection(
                    'Notificaciones de Hábitos',
                    'Recibe recordatorios diarios por la mañana y por la tarde',
                    _habitNotificationsEnabled,
                    _notificationsEnabled,
                    optionFontSize,
                    (value) async {
                      if (_notificationsEnabled) {
                        await _notificationManager.setHabitNotificationsEnabled(value);
                        setState(() {
                          _habitNotificationsEnabled = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: scaleHeight(20)),
                  
                  _buildNotificationSection(
                    'Notificaciones de Hobbies',
                    'Recibe recordatorios 5 minutos antes de tus hobbies programados',
                    _hobbyNotificationsEnabled,
                    _notificationsEnabled,
                    optionFontSize,
                    (value) async {
                      if (_notificationsEnabled) {
                        await _notificationManager.setHobbyNotificationsEnabled(value);
                        setState(() {
                          _hobbyNotificationsEnabled = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: scaleHeight(20)),
                  
                  _buildNotificationSection(
                    'Notificaciones de Rachas',
                    'Recibe recordatorios para mantener tu racha de actividades',
                    _streakNotificationsEnabled,
                    _notificationsEnabled,
                    optionFontSize,
                    (value) async {
                      if (_notificationsEnabled) {
                        await _notificationManager.setStreakNotificationsEnabled(value);
                        setState(() {
                          _streakNotificationsEnabled = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: scaleHeight(30)),
                  
                  // Información sobre las notificaciones
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildMainSwitch(double fontSize) {
    return Container(
      padding: EdgeInsets.all(scaleWidth(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: fontSize * 1.2,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            'Habilita o deshabilita todas las notificaciones de la aplicación',
            style: TextStyle(
              fontSize: fontSize * 0.8,
              color: Colors.grey,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activar notificaciones',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) async {
                  await _notificationManager.setNotificationsEnabled(value);
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: const Color(0xFF0047AB),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationSection(
    String title,
    String description,
    bool value,
    bool enabled,
    double fontSize,
    Function(bool) onChanged,
  ) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: EdgeInsets.all(scaleWidth(20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: scaleHeight(8)),
            Text(
              description,
              style: TextStyle(
                fontSize: fontSize * 0.8,
                color: Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: scaleHeight(16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activar',
                  style: TextStyle(
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
                Switch(
                  value: value && enabled,
                  onChanged: enabled ? onChanged : null,
                  activeColor: const Color(0xFF0047AB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(scaleWidth(20)),
      decoration: BoxDecoration(
        color: const Color(0xFFE0FFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información sobre notificaciones',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0047AB),
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(12)),
          Text(
            '• Las notificaciones de tareas se envían 5 minutos antes de la hora programada.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            '• Los recordatorios de hábitos se envían dos veces al día: a las 8:00 AM y a las 6:00 PM.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            '• Las notificaciones de hobbies te avisan 5 minutos antes de la hora programada.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            '• Las notificaciones de rachas te ayudan a mantener la consistencia en tus actividades diarias.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: scaleHeight(8)),
          Text(
            '• Para que las notificaciones funcionen correctamente, asegúrate de que los permisos estén habilitados en la configuración de tu dispositivo.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}
