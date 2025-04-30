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
          .select('id, imagen_url, user_id')
          .eq('cercle_id', widget.cercle['id']);

      setState(() {
        _imagenes = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar imágenes: ${e.toString()}', true);
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
      _mostrarMensaje('Error inesperado al subir la imagen: ${e.toString()}', true);
    }
  }

  void _mostrarDialogoConImagen(String imageUrl, String username, bool isVerified) {
    showDialog(
      context: this.context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text('Error al cargar la imagen'),
                  );
                },
              ),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDetallePublicacion(
      String imageUrl, String userId) async {
    try {
      // Verificar que la URL de la imagen sea válida
      if (imageUrl.isEmpty) {
        _mostrarMensaje('URL de imagen inválida', true);
        return;
      }

      final userRes = await _supabase
          .from('profiles')
          .select('username, is_verified')
          .eq('id', userId)
          .maybeSingle();
          
      // Si no se encontró el usuario, usar valores predeterminados
      if (userRes == null) {
        _mostrarMensaje('Información de usuario no disponible', true);
        final username = 'Anónimo';
        final isVerified = false;
        
        // Mostrar el diálogo con la información disponible (solo la imagen)
        if (!mounted) return;
        _mostrarDialogoConImagen(imageUrl, username, isVerified);
        return;
      }

      final username = userRes['username'] ?? 'usuario';
      final isVerified = userRes['is_verified'] ?? false;

      if (!mounted) return;
      
      _mostrarDialogoConImagen(imageUrl, username, isVerified);
    } catch (e) {
      _mostrarMensaje('Error al cargar detalle de la publicación: ${e.toString()}', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cercle = widget.cercle;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                cercle['nombre'] ?? 'Detalle del cercle',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            _imagenes.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text('No hay imágenes disponibles'),
                    ),
                  )
                : Expanded(
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
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
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