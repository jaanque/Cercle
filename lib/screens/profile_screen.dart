import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mi_cercle.dart';

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

  @override
  void initState() {
    super.initState();
    if (user != null) {
      fetchUserCercles();
    }
  }

  Future<void> fetchUserCercles() async {
    final response = await Supabase.instance.client
        .from('usuarios_cercles')
        .select('cercle_id, cercles(id, nombre, descripcion, user_id)')
        .eq('user_id', user!.id);

    setState(() {
      _cercles = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Perfil de usuario',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Información personal
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
                    leading: Icon(Icons.email),
                    title: Text('Correo electrónico'),
                    subtitle: Text('jhondoe@example.com'),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Fecha de registro'),
                    subtitle: Text('Abril 2025'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Cercles del usuario
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

                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(cercle['nombre'] ?? ''),
                          subtitle: Text(cercle['descripcion'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MiCercleScreen()),
                              );
                            },
                          ),
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
