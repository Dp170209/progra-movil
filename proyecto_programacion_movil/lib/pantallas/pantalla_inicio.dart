import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ChangeNotifierProvider(
      create: (_) => GestorRecordatorios(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Inicio')),
        drawer: _buildDrawer(context, user),
        body: Consumer<GestorRecordatorios>(
          builder: (context, gestor, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === RESUMEN DIARIO EXPANDIBLE ===
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Resumen Diario'),
                    subtitle: const Text('Toca para ver tu resumen'),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      StreamBuilder<List<Recordatorio>>(
                        stream: gestor.recordatorios,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final lista = snapshot.data ?? [];
                          final total = lista.length;
                          final completados = lista.where((r) => r.estado == 'completado').length;
                          final pendientes = lista.where((r) => r.estado != 'completado').toList();
                          pendientes.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
                          final urgentes = pendientes.take(3).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• Tareas hechas: $completados/$total'),
                              const SizedBox(height: 4),
                              if (urgentes.isNotEmpty) ...[
                                Text(
                                  '• Tareas urgentes:',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                ...urgentes.map((r) => Text('  - ${r.titulo}')),
                                const SizedBox(height: 4),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/resumen'),
                                  child: const Text('Ver resumen completo'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // === BIENVENIDA Y ACCIONES RÁPIDAS ===
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, User? user) {
    return Drawer(
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
            onTap: () => Navigator.pushNamed(context, '/recordatorios'),
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
    );
  }
}