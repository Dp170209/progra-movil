// lib/servicios.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ServicioFacial {
  ServicioFacial._();
  static final ServicioFacial instancia = ServicioFacial._();

  // Usamos las opciones por defecto:
  final _detector = FaceDetector(
    options: FaceDetectorOptions(),  // sin parámetros
  );

  Future<String?> capturarYSubir(File imagen) async {
    final rostros = await _detector.processImage(
      InputImage.fromFile(imagen),
    );
    if (rostros.isEmpty) return null;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final referencia = FirebaseStorage.instance
        .ref('perfiles_faciales')
        .child('$uid.jpg');
    await referencia.putFile(imagen);
    return referencia.getDownloadURL();
  }
}
