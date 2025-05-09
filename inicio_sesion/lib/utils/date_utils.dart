import 'package:intl/intl.dart';

// Obtener todos los días del mes actual
List<DateTime> getDaysInMonth(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final daysBefore = first.weekday % 7;
  final firstToDisplay = first.subtract(Duration(days: daysBefore));
  final last = DateTime(month.year, month.month + 1, 0);
  
  var lastToDisplay = last.add(Duration(days: 7 - last.weekday % 7));
  if (lastToDisplay.difference(last).inDays == 7) {
    lastToDisplay = lastToDisplay.subtract(const Duration(days: 7));
  }
  
  return daysInRange(firstToDisplay, lastToDisplay).toList();
}

// Obtener rango de fechas
Iterable<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime(first.year, first.month, first.day + index),
  );
}

// Formatear tiempo (HH:MM:SS)
String formatTime(int hours, int minutes, int seconds) {
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// Formatear fecha según locale
String formatDate(DateTime date, {String locale = 'es'}) {
  try {
    return DateFormat.yMMMd(locale).format(date);
  } catch (e) {
    return DateFormat.yMMMd().format(date);
  }
}