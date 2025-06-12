import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/servicios.dart';

class LoginProvider extends ChangeNotifier {
  TextEditingController correoCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();

  bool cargando = false;
  String error = '';
  bool tieneRostro = false;

  LoginProvider() {
    verificarRostroRegistrado();
  }

  Future<void> verificarRostroRegistrado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();
        final data = doc.data();
        bool nuevo = data?['fotoPerfil'] != null;
        if (nuevo != tieneRostro) {
          tieneRostro = nuevo;
          notifyListeners();
        }
      } catch (e) {
        tieneRostro = false;
        notifyListeners();
      }
    } else {
      if (tieneRostro) {
        tieneRostro = false;
        notifyListeners();
      }
    }
  }

  Future<void> loginEmail(BuildContext context) async {
    // Iniciar carga
    cargando = true;
    error = '';
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      await verificarRostroRegistrado();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Error desconocido';
    } catch (e) {
      error = 'Error: $e';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> loginFacial(BuildContext context) async {
    cargando = true;
    error = '';
    notifyListeners();

    try {
      final XFile? foto = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (foto == null) {
        error = 'Operación cancelada';
        cargando = false;
        notifyListeners();
        return;
      }
      final File file = File(foto.path);
      final bool match = await ServicioFacial.instancia.verificarRostro(file);
      if (match) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        error = 'Rostro no reconocido';
      }
    } catch (e) {
      error = 'Error facial: $e';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    correoCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
