// lib/pantallas/pantalla_login.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/servicios.dart';

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

  @override
  void initState() {
    super.initState();
    _verificarRostroRegistrado();
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
        // Obtener usuario actual y navegar
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = 'Rostro no reconocido');
      }
    } catch (e) {
      setState(() => _error = 'Error facial: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _loginEmail,
                  child: const Text('Iniciar sesión'),
                ),
            if (_tieneRostro) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loginFacial,
                icon: const Icon(Icons.face),
                label: const Text('Iniciar con rostro'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/registro');
              },
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}
