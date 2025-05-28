// lib/pantallas/pantalla_registro.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_login.dart';
import 'pantalla_registro_facial.dart';

// Helper para fade
Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, animation, __) => FadeTransition(
      opacity: animation,
      child: page,
    ),
  );
}

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  String _error = '';

  Future<void> _registrar() async {
    setState(() { _cargando = true; _error = ''; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final uid = cred.user!.uid;
      final email = _correoCtrl.text.trim();
      final nombre = email.split('@').first;
      final pass = _passCtrl.text.trim();
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        {
          'correo': email,
          'nombre': nombre,
          'contrasena': pass,
          'creadoEn': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        _fadeRoute(const PantallaRegistroFacial()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error de autenticación');
    } catch (e) {
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Crear cuenta', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error.isNotEmpty)
                    Text(_error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _registrar,
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Crear cuenta'),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      _fadeRoute(const PantallaLogin()),
                    ),
                    child: const Text('¿Ya tienes cuenta? Iniciar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
