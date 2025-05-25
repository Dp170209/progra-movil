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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final repo = RepositorioHabitos();
    final hist = await repo.conteoPorHora();
    final mh = await repo.mejorHora();
    setState(() {
      _histograma = hist;
      _mejorHora = mh;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext c) {
    if (_loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text('Sugerencias Inteligentes')),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text('Tus hábitos por hora', style: TextStyle(fontSize: 18)),
          SizedBox(height: 200, child: _buildChart()),
          SizedBox(height: 20),
          _mejorHora != null
              ? ElevatedButton.icon(
                icon: Icon(Icons.schedule),
                label: Text('Sugerir recordatorio a las $_mejorHora:00'),
                onPressed: () {
                  // Navega a formulario de creación pasando la hora sugerida
                  Navigator.pushNamed(
                    c,
                    '/crearRecordatorio',
                    arguments: {'sugerenciaHora': _mejorHora},
                  );
                },
              )
              : Text('Aún no hay datos para sugerir.'),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots =
        _histograma.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('${v.toInt()}h'),
            ),
          ),
        ),
        lineBarsData: [LineChartBarData(spots: spots)],
      ),
    );
  }
}
