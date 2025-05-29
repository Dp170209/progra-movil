// lib/pantallas/pantalla_login.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/servicios.dart';
import 'pantalla_registro.dart';

/// Helper para transición fade
Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder:
        (_, animation, __) => FadeTransition(opacity: animation, child: page),
  );
}

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _cargando = false;
  String _error = '';
  bool _tieneRostro = false;

  // Control de intentos faciales
  int _intentosFacial = 0;
  static const int _maxIntentosFacial = 3;

  @override
  void initState() {
    super.initState();
    _verificarRostroRegistrado();
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarRostroRegistrado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      setState(() {
        _tieneRostro = doc.data()?['fotoPerfil'] != null;
      });
    }
  }

  Future<void> _loginEmail() async {
    setState(() {
      _cargando = true;
      _error = '';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _correoCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error desconocido');
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginFacial() async {
    // Si ya agotó los intentos, mostrar fallback
    if (_intentosFacial >= _maxIntentosFacial) {
      _mostrarDialogoFallback();
      return;
    }

    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final XFile? foto = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (foto == null) {
        setState(() {
          _error = 'Operación cancelada';
          _cargando = false;
        });
        return;
      }
      final File file = File(foto.path);
      final bool match = await ServicioFacial.instancia.verificarRostro(file);

      if (match) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _intentosFacial++;
        if (_intentosFacial < _maxIntentosFacial) {
          setState(() {
            _error =
                'Rostro no reconocido. Intentos restantes: '
                '${_maxIntentosFacial - _intentosFacial}';
          });
        } else {
          _mostrarDialogoFallback();
        }
      }
    } catch (e) {
      setState(() => _error = 'Error facial: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoFallback() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Intentos agotados'),
            content: const Text(
              'No se pudo reconocer tu rostro tras varios intentos.\n'
              'Por favor, inicia sesión con correo y contraseña.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _intentosFacial = 0;
                    _error = '';
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bienvenido', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error.isNotEmpty)
                    Text(_error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child:
                        _cargando
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                              onPressed: _loginEmail,
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Iniciar sesión'),
                            ),
                  ),
                  if (_tieneRostro) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loginFacial,
                        icon: const Icon(Icons.face),
                        label: const Text('Iniciar con rostro'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pushReplacement(_fadeRoute(const PantallaRegistro())),
                    child: const Text('¿No tienes cuenta? Regístrate'),
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
