// lib/gestores/gestor_notificaciones.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../modelos/recordatorio.dart';

class GestorNotificaciones extends ChangeNotifier {
  static final FlutterLocalNotificationsPlugin _notificacionesPlugin =
      FlutterLocalNotificationsPlugin();

  final List<String> _mensajes = [];

  List<String> get mensajes => List.unmodifiable(_mensajes);

  /// Inicializa el plugin, zonas horarias y carga historial
  static Future<void> inicializar() async {
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: initAndroid);

    await _notificacionesPlugin.initialize(initSettings);

    tzdata.initializeTimeZones();
  }

  /// Cargar historial persistente
  Future<void> cargarMensajes() async {
    final prefs = await SharedPreferences.getInstance();
    _mensajes.clear();
    _mensajes.addAll(prefs.getStringList('historial_notificaciones') ?? []);
    notifyListeners();
  }

  /// Guardar historial persistente
  Future<void> _guardarMensajes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('historial_notificaciones', _mensajes);
  }

  /// Programa una notificación una hora antes del recordatorio.
  Future<void> programarNotificacion(Recordatorio r) async {
    final ahora = DateTime.now();
    final fechaNotificacion = r.fechaHora.subtract(const Duration(hours: 1));

    if (fechaNotificacion.isBefore(ahora)) return;

    final id = _generarIdDesde(r.id);

    await _notificacionesPlugin.zonedSchedule(
      id,
      'Recordatorio: ${r.titulo}',
      'Falta 1 hora para tu recordatorio',
      tz.TZDateTime.from(fechaNotificacion, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorio_channel',
          'Recordatorios',
          channelDescription: 'Notificaciones de recordatorios',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    final mensaje = '🕐 ${r.titulo} - Notif. ${fechaNotificacion.hour}:${fechaNotificacion.minute.toString().padLeft(2, '0')}';
    _mensajes.add(mensaje);
    await _guardarMensajes();
    notifyListeners();
  }

  /// Cancela una notificación agendada usando el ID del recordatorio.
  Future<void> cancelarNotificacion(String recordatorioId) async {
    final id = _generarIdDesde(recordatorioId);
    await _notificacionesPlugin.cancel(id);
  }

  /// Limpia historial de notificaciones
  Future<void> limpiarMensajes() async {
    _mensajes.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historial_notificaciones');
    notifyListeners();
  }

  /// Generar ID numérico único a partir del ID del recordatorio
  int _generarIdDesde(String id) => id.hashCode.abs();
}
