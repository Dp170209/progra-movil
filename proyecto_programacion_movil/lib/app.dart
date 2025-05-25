import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_programacion_movil/pantallas/pantalla_recordatorio.dart';

// Pantallas
import 'pantallas/pantalla_login.dart';
import 'pantallas/pantalla_registro.dart';
import 'pantallas/pantalla_registro_facial.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_sugerencias.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartRemind AI',
      locale: const Locale('es'), // Establece idioma español
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés (por compatibilidad)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const _AuthWrapper(),
        '/login': (_) => const PantallaLogin(),
        '/registro': (_) => const PantallaRegistro(),
        '/registro-facial': (_) => const PantallaRegistroFacial(),
        '/home': (_) => const PantallaInicio(),
        '/recordatorios': (_) => const PantallaRecordatorios(),
        '/sugerencias': (_) => const PantallaSugerencias(),
      },
    );
  }
}

/// Este widget decide si mostramos login o directamente el home
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras carga el estado:
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si está logueado, vamos al home:
        if (snapshot.hasData) {
          return const PantallaInicio();
        }
        // Si no, al login:
        return const PantallaLogin();
      },
    );
  }
}
