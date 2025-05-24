import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});  // Usamos super.key

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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;  // Verifica antes de usar context
      // Al crear el usuario, vamos a la captura facial:
      Navigator.pushReplacementNamed(context, '/registro-facial');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error desconocido');
    } catch (e) {
      setState(() => _error = 'Error: $e');
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
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: const TextStyle(color: Colors.red),
              ),
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
