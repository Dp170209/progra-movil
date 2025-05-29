// lib/pantallas/pantalla_login_facial.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/servicios.dart';

class PantallaLoginFacial extends StatefulWidget {
  const PantallaLoginFacial({super.key});

  @override
  State<PantallaLoginFacial> createState() => _PantallaLoginFacialState();
}

class _PantallaLoginFacialState extends State<PantallaLoginFacial> {
  int _intentos = 0;
  bool _cargando = false;
  String _mensaje = '';

  Future<void> _verificar() async {
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.camera);

    if (imagen == null) {
      setState(() {
        _cargando = false;
        _mensaje = 'No se seleccionó ninguna imagen';
      });
      return;
    }

    final archivo = File(imagen.path);
    final coincide = await ServicioFacial.instancia.verificarRostro(archivo);

    if (!mounted) return;

    if (coincide) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _intentos++;
      if (_intentos >= 3) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _mensaje = 'El rostro no coincide. Intento $_intentos de 3.';
        });
      }
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación Facial')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_mensaje.isNotEmpty)
                Text(_mensaje, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: _verificar,
                    icon: const Icon(Icons.face),
                    label: const Text('Verificar rostro'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
