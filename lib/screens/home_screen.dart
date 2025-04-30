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
    // Paso 1: Obtener los IDs de cercles a los que pertenece el usuario
    final resCercles = await supabase
        .from('usuarios_cercles')
        .select('cercle_id')
        .eq('user_id', userId);

    final List<String> cercleIds = List<String>.from(resCercles.map((e) => e['cercle_id']));
    if (cercleIds.isEmpty) return [];

    // Paso 2: Obtener publicaciones con datos de cercles
    final resPublicaciones = await supabase
        .from('publicaciones')
        .select('*, cercles(nombre,is_verified)')
        .inFilter('cercle_id', cercleIds)
        .order('creado_en', ascending: false);

    // Paso 3: Obtener todos los perfiles de los autores
    final userIds = resPublicaciones.map<String>((e) => e['user_id'] as String).toSet().toList();

    final resPerfiles = await supabase
        .from('profiles')
        .select('id, username, is_verified')
        .inFilter('id', userIds);

    final perfilMap = { for (var p in resPerfiles) p['id']: p };

    // Paso 4: Unir datos y retornar
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
    } catch (e) {
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
    if (showMenu) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
        body: _buildBody(context),
      );
    } else {
      return _buildBody(context);
    }
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
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(pub.imagenUrl, fit: BoxFit.cover, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
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
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.verified, color: Colors.blue, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Publicado por ${pub.username}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (pub.usuarioVerificado)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.verified, color: Colors.green, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Publicado el: ${pub.creadoEn.toLocal()}'),
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