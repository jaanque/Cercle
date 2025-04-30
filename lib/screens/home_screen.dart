import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class Publicacion {
  final String id;
  final String imagenUrl;
  final DateTime creadoEn;
  final String cercleNombre;
  final bool cercleVerificado;
  final String username;
  final bool usuarioVerificado;

  Publicacion({
    required this.id,
    required this.imagenUrl,
    required this.creadoEn,
    required this.cercleNombre,
    required this.cercleVerificado,
    required this.username,
    required this.usuarioVerificado,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json, Map<String, dynamic> perfil) {
    final cercle = json['cercles'] ?? {};
    return Publicacion(
      id: json['id'],
      imagenUrl: json['imagen_url'],
      creadoEn: DateTime.parse(json['creado_en']),
      cercleNombre: cercle['nombre'] ?? 'Cercle desconocido',
      cercleVerificado: cercle['is_verified'] ?? false,
      username: perfil['username'] ?? 'Usuario desconocido',
      usuarioVerificado: perfil['is_verified'] ?? false,
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

    final userIds = resPublicaciones.map<String>((e) => e['user_id'] as String).toSet().toList();

    final resPerfiles = await supabase
        .from('profiles')
        .select('id, username, is_verified')
        .inFilter('id', userIds);

    final perfilMap = { for (var p in resPerfiles) p['id']: p };

    return resPublicaciones.map<Publicacion>((json) {
      final perfil = perfilMap[json['user_id']] ?? {};
      return Publicacion.fromJson(json, perfil);
    }).toList();
  }
}

class HomeScreen extends StatelessWidget {
  final String username;
  final bool showMenu;
  final AuthService _authService = AuthService();
  final publicacionesService = PublicacionesService();

  final Color _coral = const Color(0xFFE87F65);

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

            return Card(
              elevation: 4,
              shadowColor: _coral.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(pub.imagenUrl, fit: BoxFit.cover, width: double.infinity),
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
                                child: Icon(Icons.verified, color: _coral, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Publicado por ${pub.username}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            if (pub.usuarioVerificado)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.verified_user, color: _coral, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Publicado el: ${pub.creadoEn.toLocal()}',
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