import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'gestores/gestor_recordatorios.dart';
import 'gestores/gestor_notificaciones.dart'; 
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GestorNotificaciones.inicializar();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GestorRecordatorios()),
        ChangeNotifierProvider(create: (_) => GestorNotificaciones()), 
      ],
      child: const MainApp(),
    ),
  );
}
