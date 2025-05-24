import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Usuario'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Recordatorios'),
              onTap: () {
                Navigator.pushNamed(context, '/recordatorios');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mood),
              title: const Text('Estado de ánimo'),
              onTap: () => Navigator.pushNamed(context, '/animo'),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Sugerencias'),
              onTap: () => Navigator.pushNamed(context, '/sugerencias'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Desbloqueo facial'),
              onTap: () => Navigator.pushNamed(context, '/desbloqueo'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${user?.email ?? 'usuario'}!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Ver mis recordatorios'),
              onPressed: () => Navigator.pushNamed(context, '/recordatorios'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_done),
              label: const Text('Probar conexión a Firestore'),
              onPressed: () async {
                final mensaje = await _testFirestore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mensaje)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _testFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('prueba')
          .doc('conexion')
          .get();

      if (doc.exists) {
        print('✅ Firestore conectado: ${doc.data()}');
        return '✅ Conexión exitosa con Firestore.';
      } else {
        print('⚠️ Documento no encontrado.');
        return '⚠️ Conectado, pero el documento no existe.';
      }
    } catch (e) {
      print('❌ Error de conexión con Firestore: $e');
      return '❌ Error de conexión: ${e.toString()}';
    }
  }
}
