// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'gestores/gestor_recordatorios.dart';
import 'app.dart';

/// Plugin global para notificaciones locales
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Inicializa zona horaria, plugin y canal de notificaciones
Future<void> _initNotifications() async {
  // Carga las zonas horarias
  tz.initializeTimeZones();

  // Configuración para Android
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  // Configuración para iOS
  final iosSettings = DarwinInitializationSettings();

  // Inicialización combinada
  final initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notificationsPlugin.initialize(initSettings);

  // Crear canal para Android Oreo en adelante
  const channel = AndroidNotificationChannel(
    'reminder_channel',
    'Recordatorios',
    description: 'Notificaciones de tareas',
    importance: Importance.high,
  );
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa notificaciones antes de arrancar la interfaz
  await _initNotifications();

  // Arranque de la app con providers globales
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GestorRecordatorios()),
      ],
      child: const MainApp(),
    ),
  );
}
