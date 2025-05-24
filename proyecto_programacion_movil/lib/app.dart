import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final correoInput = emailController.text.trim();
    final passInput = passwordController.text.trim();

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('correo', isEqualTo: correoInput)
              .where('password', isEqualTo: passInput)
              .get();

      if (query.docs.isEmpty) {
        setState(() => error = 'Usuario o contraseña incorrectos');
      } else {
        final userDoc = query.docs.first.data();
      }
    } catch (e) {
      setState(() => error = 'Error al conectar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            if (error.isNotEmpty)
              Text(
                error,
                style: TextStyle(
                  color: error.contains("exitoso") ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: login,
                  child: const Text('Iniciar sesión'),
                ),
          ],
        ),
      ),
    );
  }
}
