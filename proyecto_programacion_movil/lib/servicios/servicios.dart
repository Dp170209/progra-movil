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
    final rostros = await _detector.processImage(InputImage.fromFile(imagen));
    if (rostros.isEmpty) return null;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final referencia = FirebaseStorage.instance
        .ref('perfiles_faciales')
        .child('$uid.jpg');
    await referencia.putFile(imagen);
    return referencia.getDownloadURL();
  }

  /// Verifica que el nuevo rostro coincida con el registrado.
  Future<bool> verificarRostro(File nuevaImagen) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // 1) Obtiene URL almacenada en Firestore
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
    final url = doc.data()?['fotoPerfil'] as String?;
    if (url == null) return false;

    Uint8List? bytes;
    try {
      // 2) Descarga la imagen registrada de Storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      bytes = await ref.getData();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // La selfie almacenada ya no existe
        return false;
      }
      rethrow;
    }
    if (bytes == null) return false;

    // Guarda temporalmente
    final tempDir = Directory.systemTemp;
    final refFile = File('${tempDir.path}/${user.uid}_ref.jpg');
    await refFile.writeAsBytes(bytes);

    // 3) Procesa ambas imágenes
    final rostrosRef = await _detector.processImage(
      InputImage.fromFile(refFile),
    );
    final rostrosNew = await _detector.processImage(
      InputImage.fromFile(nuevaImagen),
    );
    if (rostrosRef.isEmpty || rostrosNew.isEmpty) return false;

    // 4) Compara atributos básicos del primer rostro detectado
    final f1 = rostrosRef.first;
    final f2 = rostrosNew.first;

    // Valores de Euler Y pueden ser null
    final double y1 = f1.headEulerAngleY ?? 0.0;
    final double y2 = f2.headEulerAngleY ?? 0.0;

    // Comparar posición y tamaño relativos
    final ratioW = (f1.boundingBox.width / f2.boundingBox.width).abs();
    final ratioH = (f1.boundingBox.height / f2.boundingBox.height).abs();
    final angleDiff = (y1 - y2).abs();

    // Umbrales de tolerancia (ajustar según pruebas)
    if (ratioW < 1.2 && ratioH < 1.2 && angleDiff < 15) {
      return true;
    }

    return false;
  }
}
