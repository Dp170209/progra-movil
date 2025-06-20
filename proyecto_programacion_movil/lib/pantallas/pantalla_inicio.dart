import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';
import '../providers/theme_provider.dart';
import '../providers/inicio_provider.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconAnimationController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDark;
    final user = FirebaseAuth.instance.currentUser;
    final gestor = context.watch<GestorRecordatorios>();
    final inicioProv = context.watch<InicioProvider>();

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (open) {
        if (open) {
          _iconAnimationController.forward();
        } else {
          _iconAnimationController.reverse();
        }
      },
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_arrow,
            progress: _iconAnimationController,
          ),
          onPressed: () {
            if (_scaffoldKey.currentState!.isDrawerOpen) {
              Navigator.pop(context);
            } else {
              _scaffoldKey.currentState!.openDrawer();
            }
          },
        ),
        title: const Text('Tablero Inteligente'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProv.toggle(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user, isDark),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Animación
          Lottie.asset(
            isDark ? 'assets/welcome_dark.json' : 'assets/welcome_light.json',
            height: 180,
          ),
          const SizedBox(height: 12),
          // Saludo
          Text(
            '¡Buenos días, ${user?.email?.split('@').first ?? 'amigo'}!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Resumen Diario
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.calendar_today, size: 32),
              title: const Text(
                'Resumen Diario',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                StreamBuilder<List<Recordatorio>>(
                  stream: gestor.recordatorios,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lista = snapshot.data ?? [];
                    final total = lista.length;
                    final completados =
                        lista.where((r) => r.estado == 'completado').length;
                    final pendientes =
                        lista.where((r) => r.estado != 'completado').toList()
                          ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
                    final urgentes = pendientes.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✅ Completadas: $completados/$total'),
                        const SizedBox(height: 8),
                        if (urgentes.isNotEmpty) ...[
                          const Text('⚠️ Urgentes:'),
                          ...urgentes.map((r) => Text('- ${r.titulo}')),
                          const SizedBox(height: 8),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/resumen'),
                            child: const Text('Ver completo'),
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
          // Consejos dinámicos usando InicioProvider
          Card(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      '"${inicioProv.currentQuote}"',
                      key: ValueKey(inicioProv.quoteIndex),
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(),
                  const Text(
                    'Tip del día:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      inicioProv.currentTip,
                      key: ValueKey(inicioProv.tipIndex),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/recordatorios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Agenda tu siguiente tarea',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, User? user, bool isDark) => Drawer(
    child: Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          accountName: Text(user?.displayName ?? '¡Hola!'),
          accountEmail: Text(user?.email ?? ''),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child:
                user?.photoURL != null
                    ? ClipOval(
                      child: Image.network(user!.photoURL!, fit: BoxFit.cover),
                    )
                    : const Icon(Icons.person, size: 40),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _drawerItem(
                Icons.notifications,
                'Recordatorios',
                '/recordatorios',
              ),
              _drawerItem(Icons.mood, 'Estado de ánimo', '/animo'),
              _drawerItem(Icons.lightbulb, 'Sugerencias', '/sugerencias'),
              _drawerItem(Icons.camera_alt, 'Desbloqueo facial', '/desbloqueo'),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('Cerrar sesión'),
          onTap: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );

  ListTile _drawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
