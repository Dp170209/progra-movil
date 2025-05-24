import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../servicios.dart';

class PantallaRegistroFacial extends StatefulWidget {
  const PantallaRegistroFacial({super.key});

  @override
  State<PantallaRegistroFacial> createState() => _PantallaRegistroFacialState();
}

class _PantallaRegistroFacialState extends State<PantallaRegistroFacial> {
  bool _cargando = false;
  String _mensaje = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _tomarSelfie() async {
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
      if (foto == null) {
        setState(() {
          _mensaje = 'Operación cancelada';
          _cargando = false;
        });
        return;
      }

      final File archivo = File(foto.path);
      final url = await ServicioFacial.instancia.capturarYSubir(archivo);

      if (url == null) {
        setState(() => _mensaje = 'No se detectó ningún rostro en la foto.');
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({'fotoPerfil': url}, SetOptions(merge: true));

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _mensaje = 'Error al procesar la imagen: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro facial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Toma una selfie para registrar tu perfil facial.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_mensaje.isNotEmpty)
              Text(
                _mensaje,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _tomarSelfie,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar selfie'),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (mounted) Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Omitir (más tarde)'),
            ),
          ],
        ),
      ),
    );
  }
}
