import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';  // Importamos intl

class Publicacion {
  final String id;
  final String imagenUrl;
  final DateTime creadoEn;
  final String cercleNombre;
  final bool cercleVerificado;

  Publicacion({
    required this.id,
    required this.imagenUrl,
    required this.creadoEn,
    required this.cercleNombre,
    required this.cercleVerificado,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    final cercle = json['cercles'] ?? {};
    return Publicacion(
      id: json['id'],
      imagenUrl: json['imagen_url'],
      creadoEn: DateTime.parse(json['creado_en']),
      cercleNombre: cercle['nombre'] ?? 'Cercle desconocido',
      cercleVerificado: cercle['is_verified'] ?? false,
    );
  }
}

class PublicacionesService {
  final supabase = Supabase.instance.client;

  Future<List<Publicacion>> obtenerPublicacionesDelUsuario(String userId) async {
    final resCercles = await supabase
        .from('usuarios_cercles')
        .select('cercle_id')
        .eq('user_id', userId);

    final List<String> cercleIds = List<String>.from(resCercles.map((e) => e['cercle_id']));
    if (cercleIds.isEmpty) return [];

    final resPublicaciones = await supabase
        .from('publicaciones')
        .select('*, cercles(nombre,is_verified)')
        .inFilter('cercle_id', cercleIds)
        .order('creado_en', ascending: false);

    return resPublicaciones.map<Publicacion>((json) {
      return Publicacion.fromJson(json);
    }).toList();
  }
}

class HomeScreen extends StatelessWidget {
  final String username;
  final bool showMenu;
  final AuthService _authService = AuthService();
  final publicacionesService = PublicacionesService();

  final Color _coral = const Color(0xFFE87F65);
  final Color _verificadoColor = const Color(0xFFDA7756);

  HomeScreen({
    super.key,
    required this.username,
    this.showMenu = true,
  });

  Future<void> _signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return showMenu
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Inicio'),
              backgroundColor: _coral,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOut(context),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
            body: _buildBody(context),
          )
        : _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('No hay usuario logueado'));
    }

    return FutureBuilder<List<Publicacion>>(
      future: publicacionesService.obtenerPublicacionesDelUsuario(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final publicaciones = snapshot.data ?? [];

        if (publicaciones.isEmpty) {
          return const Center(child: Text('No hay publicaciones en tus cercles'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: publicaciones.length,
          itemBuilder: (context, index) {
            final pub = publicaciones[index];

            // Formatear la fecha y la hora
            final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
            final String formattedDate = dateFormat.format(pub.creadoEn);

            return Card(
              elevation: 4,
              shadowColor: _coral.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aseguramos que la imagen sea cuadrada (1:1)
                  AspectRatio(
                    aspectRatio: 1, // Relación 1:1
                    child: Image.network(pub.imagenUrl, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pub.cercleNombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (pub.cercleVerificado)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.verified, color: _verificadoColor, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Mostrar la fecha y hora con el formato deseado
                        Text(
                          'Publicado el: $formattedDate',
                          style: const TextStyle(fontSize: 13, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}