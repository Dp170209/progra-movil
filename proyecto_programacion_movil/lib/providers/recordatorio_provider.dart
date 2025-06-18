// lib/providers/recordatorio_provider.dart
import 'package:flutter/material.dart';

import '../gestores/gestor_recordatorios.dart';
import '../modelos/recordatorio.dart';
import '../repositorios/repositorio_habito.dart';
import '../servicios/servicio_pnl.dart';
import '../servicios/servicio_voz.dart';

class RecordatorioProvider extends ChangeNotifier {
  final GestorRecordatorios _gestor = GestorRecordatorios();
  String _filtroPrioridad = 'todas';

  RecordatorioProvider();

  // Getter y setter para el filtro de prioridad
  String get filtroPrioridad => _filtroPrioridad;
  set filtroPrioridad(String valor) {
    _filtroPrioridad = valor;
    notifyListeners();
  }

  // Stream de recordatorios en crudo
  Stream<List<Recordatorio>> get recordatorios => _gestor.recordatorios;

  // Filtrado por prioridad
  List<Recordatorio> filtrar(List<Recordatorio> lista) {
    if (_filtroPrioridad == 'todas') return lista;
    return lista.where((r) => r.prioridad == _filtroPrioridad).toList();
  }

  // Cálculo de tiempo restante hasta 'fecha'
  String calcularTiempoRestante(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = fecha.difference(ahora);

    if (diferencia.isNegative) return '⏰ Ya vencido';

    final dias = diferencia.inDays;
    final horas = diferencia.inHours % 24;
    final minutos = diferencia.inMinutes % 60;

    if (dias > 0) {
      return 'En $dias día${dias > 1 ? 's' : ''} y $horas h';
    }
    if (horas > 0) {
      return 'En $horas h y $minutos min';
    }
    return 'En $minutos min';
  }

  // Alternar estado y registrar/eliminar hábito
  Future<void> alternarEstado(BuildContext context, Recordatorio r) async {
    final estabaCompletado = r.estado == 'completado';
    await _gestor.alternarEstado(r);
    if (!estabaCompletado) {
      await RepositorioHabitos().registrarHabito(r.id, r.titulo);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Hábito registrado')));
    } else {
      await RepositorioHabitos().eliminarHabito(r.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Marcado como pendiente y hábito eliminado'),
        ),
      );
    }
  }

  // Crear recordatorio manualmente
  Future<void> agregarRecordatorio(BuildContext context, Recordatorio r) async {
    await _gestor.agregar(r);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Recordatorio creado')));
  }

  // Editar recordatorio existente
  Future<void> editarRecordatorio(BuildContext context, Recordatorio r) async {
    await _gestor.editar(r);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Recordatorio actualizado')));
  }


  Future<void> agregarPorVoz(BuildContext context) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🎙️ Escuchando...')));
    final comando = await ServicioVoz.instance.escucharComando();
    if (comando == null || comando.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ No te escuché bien')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('⏳ Procesando...')));
    final json = await ServicioPNL.instance.procesarFrase(comando);
    if (json == null ||
        !json.containsKey('titulo') ||
        !json.containsKey('fecha')) {
      await ServicioVoz.instance.hablar('No entendí tu mensaje');
      return;
    }
    try {
      final fechaUtc = DateTime.parse(json['fecha']);
      final fecha = fechaUtc.toLocal();
      final titulo = json['titulo'] as String;
      final nuevo = Recordatorio(
        id: '',
        titulo: titulo,
        fechaHora: fecha,
        prioridad: 'media',
      );
      await _gestor.agregar(nuevo);
      final respuesta =
          'Recordatorio "$titulo" para ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')} creado';
      await ServicioVoz.instance.hablar(respuesta);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ $respuesta')));
    } catch (e) {
      await ServicioVoz.instance.hablar('La fecha no parece válida');
    }
  }

  Future<void> crearPorTexto(BuildContext context, String texto) async {
    if (texto.isEmpty) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('⏳ Procesando...')));
    final json = await ServicioPNL.instance.procesarFrase(texto);
    if (json == null ||
        !json.containsKey('titulo') ||
        !json.containsKey('fecha')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se entendió el mensaje')),
      );
      return;
    }
    try {
      final fechaUtc = DateTime.parse(json['fecha']);
      final fecha = fechaUtc.toLocal();
      final titulo = json['titulo'] as String;
      final nuevo = Recordatorio(id: '', titulo: titulo, fechaHora: fecha);
      await _gestor.agregar(nuevo);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Recordatorio creado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Fecha no válida')));
    }
  }

  // Eliminar recordatorio
  void eliminar(BuildContext context, String id) {
    _gestor.eliminar(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑 Recordatorio eliminado')));
  }

  @override
  void dispose() {
    _gestor.dispose();
    super.dispose();
  }
}