// lib/providers/registro_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroProvider extends ChangeNotifier {
  TextEditingController correoCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();

  bool cargando = false;
  String error = '';

  RegistroProvider();

  Future<void> registrar(BuildContext context) async {
    cargando = true;
    error = '';
    notifyListeners();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      final uid = cred.user!.uid;
      final email = correoCtrl.text.trim();
      final nombre = email.split('@').first;
      final pass = passCtrl.text.trim();
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'correo': email,
        'nombre': nombre,
        'contrasena': pass,
        'creadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/registro-facial');
      }
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Error de autenticación';
    } catch (e) {
      error = 'Error inesperado: $e';
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
