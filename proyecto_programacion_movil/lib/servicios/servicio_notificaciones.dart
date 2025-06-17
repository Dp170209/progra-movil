// lib/servicios/servicio_notificaciones.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // notificationsPlugin global

class ServicioNotificaciones {
  ServicioNotificaciones._();
  static final ServicioNotificaciones instancia = ServicioNotificaciones._();

  /// Programa una notificación 1 hora antes de [fechaHora]
  Future<void> scheduleNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      fechaHora.subtract(const Duration(hours: 1)),
      tz.local,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Recordatorios',
          channelDescription: 'Notificaciones de tareas',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// Cancela la notificación con [id]
  Future<void> cancelNotificacion(int id) async {
    await notificationsPlugin.cancel(id);
  }
}
