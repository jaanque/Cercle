import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CercleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cercle;

  const CercleDetailScreen({super.key, required this.cercle});

  @override
  State<CercleDetailScreen> createState() => _CercleDetailScreenState();
}

class _CercleDetailScreenState extends State<CercleDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  List<Map<String, dynamic>> _imagenes = [];

  @override
  void initState() {
    super.initState();
    _cargarImagenes();
  }

  void _mostrarMensaje(String mensaje, [bool error = false]) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _cargarImagenes() async {
    try {
      final res = await _supabase
          .from('publicaciones')
          .select('imagen_url, user_id')
          .eq('cercle_id', widget.cercle['id']);

      setState(() {
        _imagenes = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar imágenes', true);
    }
  }

  Future<void> _subirImagen() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        _mostrarMensaje('No seleccionaste ninguna imagen.');
        return;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _mostrarMensaje('Usuario no autenticado.', true);
        return;
      }

      final fileBytes = await pickedFile.readAsBytes();
      final fileName = '${_uuid.v4()}${extension(pickedFile.name)}';
      final storagePath = 'publicaciones/$fileName';

      await _supabase.storage
          .from('publicaciones')
          .uploadBinary(storagePath, fileBytes);

      final imageUrl =
          _supabase.storage.from('publicaciones').getPublicUrl(storagePath);

      await _supabase.from('publicaciones').insert({
        'user_id': userId,
        'cercle_id': widget.cercle['id'],
        'imagen_url': imageUrl,
      });

      _mostrarMensaje('Imagen subida correctamente.');
      await _cargarImagenes();
    } catch (e) {
      _mostrarMensaje('Error inesperado al subir la imagen.', true);
    }
  }

  Future<void> _mostrarDetallePublicacion(
      String imageUrl, String userId) async {
    try {
      final userRes = await _supabase
          .from('profiles')
          .select('username, is_verified')
          .eq('id', userId)
          .maybeSingle();

      if (userRes == null) {
        _mostrarMensaje('Usuario no encontrado', true);
        return;
      }

      final username = userRes['username'] ?? 'usuario';
      final isVerified = userRes['is_verified'] ?? false;

      showDialog(
        context: this.context,
        builder: (BuildContext context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(imageUrl),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'by @$username',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.verified,
                        color: Color(0xFFDA7756),
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } catch (e) {
      _mostrarMensaje('Error al cargar detalle de la publicación.', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cercle = widget.cercle;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(cercle['nombre'] ?? 'Detalle del cercle'),
            if (cercle['is_verified'] == true)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.verified, color: Color(0xFFDA7756), size: 20),
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cercle['nombre'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              cercle['descripcion'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _subirImagen,
              icon: const Icon(Icons.upload),
              label: const Text('Subir imagen'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _imagenes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final imagen = _imagenes[index];
                  return GestureDetector(
                    onTap: () => _mostrarDetallePublicacion(
                      imagen['imagen_url'],
                      imagen['user_id'],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imagen['imagen_url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
