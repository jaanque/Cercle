import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cercle_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _cercles = [];
  bool _isLoading = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      fetchUserProfile();
      fetchUserCercles();
    }
  }

  Future<void> fetchUserProfile() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('is_verified')
        .eq('id', user!.id)
        .single();

    setState(() {
      _isVerified = response['is_verified'] ?? false;
    });
  }

  Future<void> fetchUserCercles() async {
    final response = await Supabase.instance.client
        .from('usuarios_cercles')
        .select(
            'cercle_id, cercles(id, nombre, descripcion, user_id, publicaciones(count))')
        .eq('user_id', user!.id);

    setState(() {
      _cercles = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF333333),
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.verified,
                      color: Color(0xFFDA7756),
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Perfil de usuario',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Información personal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Fecha de registro'),
                    subtitle: Text('Abril 2025'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis cercles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_cercles.isEmpty)
                    const Text('No perteneces a ningún cercle.')
                  else
                    Column(
                      children: _cercles.map((item) {
                        final cercle = item['cercles'];
                        final postCount =
                            cercle['publicaciones'][0]['count'] ?? 0;

                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(cercle['nombre'] ?? ''),
                          subtitle: Text(
                            '${cercle['descripcion'] ?? ''}\nPublicaciones: $postCount',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CercleDetailScreen(cercle: cercle),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
