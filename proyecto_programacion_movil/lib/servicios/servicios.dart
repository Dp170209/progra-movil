// lib/servicios.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ServicioFacial {
  ServicioFacial._();
  static final ServicioFacial instancia = ServicioFacial._();

  // Detector de rostros MLKit
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Captura y sube la imagen al storage si detecta al menos un rostro.
  Future<String?> capturarYSubir(File imagen) async {
    try {
      final rostros = await _detector.processImage(InputImage.fromFile(imagen));
      if (rostros.isEmpty) return null;

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final referencia = FirebaseStorage.instance
          .ref('perfiles_faciales')
          .child('$uid.jpg');

      // Subir archivo
      await referencia.putFile(imagen);

      // Obtener URL de descarga
      final url = await referencia.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      // Manejo de errores de Storage
      print('Error Storage (capturarYSubir): ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error inesperado (capturarYSubir): $e');
      return null;
    }
  }

  /// Verifica que el nuevo rostro coincida con el registrado.
  Future<bool> verificarRostro(File nuevaImagen) async {
    // ... mismo código de antes ...
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
    final url = doc.data()?['fotoPerfil'] as String?;
    if (url == null) return false;

    Uint8List? bytes;
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      bytes = await ref.getData();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
    if (bytes == null) return false;

    final tempDir = Directory.systemTemp;
    final refFile = File('${tempDir.path}/${user.uid}_ref.jpg');
    await refFile.writeAsBytes(bytes);

    final rostrosRef = await _detector.processImage(
      InputImage.fromFile(refFile),
    );
    final rostrosNew = await _detector.processImage(
      InputImage.fromFile(nuevaImagen),
    );
    if (rostrosRef.isEmpty || rostrosNew.isEmpty) return false;

    final f1 = rostrosRef.first;
    final f2 = rostrosNew.first;
    final double y1 = f1.headEulerAngleY ?? 0.0;
    final double y2 = f2.headEulerAngleY ?? 0.0;
    final ratioW = (f1.boundingBox.width / f2.boundingBox.width).abs();
    final ratioH = (f1.boundingBox.height / f2.boundingBox.height).abs();
    final angleDiff = (y1 - y2).abs();

    if (ratioW < 1.2 && ratioH < 1.2 && angleDiff < 15) {
      return true;
    }
    return false;
  }
}
