// lib/ui/pantalla_sugerencias.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../repositorios/repositorio_habito.dart';

class PantallaSugerencias extends StatefulWidget {
  const PantallaSugerencias({super.key});

  @override
  _PantallaSugerenciasState createState() => _PantallaSugerenciasState();
}

class _PantallaSugerenciasState extends State<PantallaSugerencias> {
  Map<int, int> _histograma = {};
  int? _mejorHora;
  bool _loading = true;
  int _tareasHoy = 0;
  bool _sobrecargado = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final repo = RepositorioHabitos();
    final hist = await repo.conteoPorHora();
    final mh = await repo.mejorHora();
    final horaActual = DateTime.now().hour;
    final tareasHoy = hist[horaActual] ?? 0;

    setState(() {
      _histograma = hist;
      _mejorHora = mh;
      _tareasHoy = tareasHoy;
      _sobrecargado = tareasHoy > 5;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sugerencias Inteligentes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de Hoy',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildResumenHoy(),
              const Divider(height: 32),
              Text(
                'Hábitos por Hora',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 200, child: _buildChartPlaceholder()),
              const Divider(height: 32),
              Text(
                'Sugerencia Personalizada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildSugerencia(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenHoy() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.task,
          size: 40,
          color: _sobrecargado ? Colors.red : Colors.green,
        ),
        title: const Text('Tareas completadas esta hora'),
        subtitle: Text('$_tareasHoy tareas'),
        trailing:
            _sobrecargado
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    final spots =
        _histograma.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text('${value.toInt()}h'),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerencia() {
    if (_mejorHora == null) {
      return const Text('Aún no hay datos suficientes para sugerir.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basado en tu actividad, te sugerimos programar tu tarea a las $_mejorHora:00.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.schedule),
          label: const Text('Programar Recordatorio'),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/crearRecordatorio',
              arguments: {'sugerenciaHora': _mejorHora},
            );
          },
        ),
      ],
    );
  }
}
