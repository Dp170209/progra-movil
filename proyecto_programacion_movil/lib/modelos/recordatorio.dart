class Recordatorio {
  final String id;
  final String titulo;
  final DateTime fechaHora;
  final String uid;

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.fechaHora,
    required this.uid,
  });

Map<String, dynamic> toJson() => {
  'titulo': titulo,
  'fechaHora': fechaHora.toIso8601String(),
  'uid': uid,
};



factory Recordatorio.fromJson(String id, Map<String, dynamic> json) {
  return Recordatorio(
    id: id, 
    titulo: json['titulo'] ?? '',
    fechaHora: DateTime.parse(json['fechaHora']),
    uid: json['uid'] ?? '',
  );
}
}
