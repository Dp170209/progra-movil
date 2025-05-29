// lib/servicios/servicios.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Servicio para detección de rostros y carga de imágenes en Firebase Storage.
class ServicioFacial {
  ServicioFacial._();
  static final ServicioFacial instancia = ServicioFacial._();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<String?> capturarYSubir(File imagen) async {
    try {
      // Detección de rostros en imagen estática
      print('📷 Analizando imagen en: ${imagen.path}');
      final input = InputImage.fromFilePath(imagen.path);
      final rostros = await _detector.processImage(input);
      print('👤 Rostros detectados: ${rostros.length}');

      if (rostros.isEmpty) {
        print('⚠️ No se detectó ningún rostro en la imagen');
        return null;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('⚠️ Usuario no autenticado');
        return null;
      }
      final storageRef = FirebaseStorage.instance.ref(
        'perfiles_faciales/$uid.jpg',
      );
      final uploadTask = storageRef.putFile(imagen);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
          {'fotoPerfil': downloadUrl},
        );

        print('✅ Imagen subida y URL guardada en Firestore');
        return downloadUrl;
      } else {
        print('⚠️ Upload failed, state: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      print('🛑 FirebaseException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Verifica que el nuevo rostro coincida con el registrado.
  Future<bool> verificarRostro(File nuevaImagen) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Obtener URL de la imagen de referencia
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      final refUrl = doc.data()?['fotoPerfil'] as String?;
      if (refUrl == null) return false;

      // Descargar bytes de la imagen de referencia
      final ref = FirebaseStorage.instance.refFromURL(refUrl);
      final bytes = await ref.getData();
      if (bytes == null) return false;

      // Guardar imagen de referencia temporal
      final tempFile = File('${Directory.systemTemp.path}/${user.uid}_ref.jpg');
      await tempFile.writeAsBytes(bytes);

      // Procesar ambas imágenes
      final rostrosRef = await _detector.processImage(
        InputImage.fromFilePath(tempFile.path),
      );
      final rostrosNew = await _detector.processImage(
        InputImage.fromFilePath(nuevaImagen.path),
      );
      if (rostrosRef.isEmpty || rostrosNew.isEmpty) return false;

      if (rostrosRef.isEmpty) {
        print('❌ No se detectó rostro en la imagen de referencia');
      }
      if (rostrosNew.isEmpty) {
        print('❌ No se detectó rostro en la nueva imagen');
      }

      // Comparar ángulos y tamaños
      final f1 = rostrosRef.first;
      final f2 = rostrosNew.first;
      final y1 = f1.headEulerAngleY ?? 0.0;
      final y2 = f2.headEulerAngleY ?? 0.0;
      final ratioW = (f1.boundingBox.width / f2.boundingBox.width).abs();
      final ratioH = (f1.boundingBox.height / f2.boundingBox.height).abs();
      final angleDiff = (y1 - y2).abs();

      print('🧠 Ángulo Y referencia: ${f1.headEulerAngleY}');
      print('🧠 Ángulo Y nueva: ${f2.headEulerAngleY}');
      print('📏 Ratio ancho: $ratioW');
      print('📏 Ratio alto: $ratioH');
      print('↩️ Diferencia de ángulo: $angleDiff');

      const maxRatio = 1.6;
      const maxAngle = 25.0;
      return (ratioW < maxRatio && ratioH < maxRatio && angleDiff < maxAngle);
    } catch (e) {
      print('❌ Error en verificarRostro: $e');
      return false;
    }
  }
}
