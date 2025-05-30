// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'gestores/gestor_recordatorios.dart';

// Pantallas
import 'pantallas/pantalla_login.dart';
import 'pantallas/pantalla_registro.dart';
import 'pantallas/pantalla_registro_facial.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_sugerencias.dart';
import 'pantallas/pantalla_resumen.dart';
import 'pantallas/pantalla_recordatorio.dart';
import 'pantallas/pantalla_crear_recordatorio.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartRemind AI',
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: themeProv.mode,
      initialRoute: '/',
      routes: {
        '/': (_) => const _AuthWrapper(),
        '/login': (_) => const PantallaLogin(),
        '/registro': (_) => const PantallaRegistro(),
        '/registro-facial': (_) => const PantallaRegistroFacial(),
        '/home': (_) => const PantallaInicio(),
        '/recordatorios': (_) => const PantallaRecordatorios(),
        '/sugerencias': (_) => const PantallaSugerencias(),
        '/resumen': (_) => const PantallaResumen(),
        '/crearRecordatorio': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final sugerenciaHora = args?['sugerenciaHora'] as int?;
          return PantallaCrearRecordatorio(sugerenciaHora: sugerenciaHora);
        },
      },
    );
  }
}

/// Decide si mostrar login o inicio según autenticación
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const PantallaInicio() : const PantallaLogin();
      },
    );
  }
}