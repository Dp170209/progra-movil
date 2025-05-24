// lib/pantallas/pantalla_registro.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _correoCtrl = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _cargando    = false;
  String _error     = '';

  Future<void> _registrar() async {
    setState(() {
      _cargando = true;
      _error    = '';
    });

    try {
      // 1) Crea usuario en Auth
      final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: _correoCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

      final uid    = cred.user!.uid;
      final email  = _correoCtrl.text.trim();
      final nombre = email.split('@').first;
      final pass   = _passCtrl.text.trim();

      // 2) Guarda todos los datos en Firestore
      await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .set({
          'correo':      email,
          'nombre':      nombre,
          'contrasena':  pass,                            // campo contraseña
          'creadoEn':    FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      // 3) Navega a selfie facial
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/registro-facial');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
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
                    onPressed: _registrar,
                    child: const Text('Crear cuenta'),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('¿Ya tienes cuenta? Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}