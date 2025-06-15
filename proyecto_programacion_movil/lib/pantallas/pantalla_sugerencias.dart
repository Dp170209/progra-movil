import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/sugerencias_provider.dart';

class PantallaSugerencias extends StatelessWidget {
  const PantallaSugerencias({super.key});

  @override
  Widget build(BuildContext context) {
    final sugerenciasProv = context.watch<SugerenciasProvider>();
    if (sugerenciasProv.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final histograma = sugerenciasProv.histograma;
    final mejorHora = sugerenciasProv.mejorHora;
    final tareasHoy = sugerenciasProv.tareasHoy;
    final sobrecargado = sugerenciasProv.sobrecargado;

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
              _buildResumenHoy(tareasHoy, sobrecargado),
              const Divider(height: 32),
              Text(
                'Hábitos por Hora',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 200, child: _buildChart(histograma)),
              const Divider(height: 32),
              Text(
                'Sugerencia Personalizada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildSugerencia(context, mejorHora),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenHoy(int tareasHoy, bool sobrecargado) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.task,
          size: 40,
          color: sobrecargado ? Colors.red : Colors.green,
        ),
        title: const Text('Tareas completadas esta hora'),
        subtitle: Text('$tareasHoy tareas'),
        trailing:
            sobrecargado
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildChart(Map<int, int> histograma) {
    final spots =
        histograma.entries
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

  Widget _buildSugerencia(BuildContext context, int? mejorHora) {
    if (mejorHora == null) {
      return const Text('Aún no hay datos suficientes para sugerir.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basado en tu actividad, te sugerimos programar tu tarea a las $mejorHora:00.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.schedule),
          label: const Text('Programar Recordatorio'),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/crearRecordatorio',
              arguments: {'sugerenciaHora': mejorHora},
            );
          },
        ),
      ],
    );
  }
}
