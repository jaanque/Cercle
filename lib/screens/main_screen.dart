import 'package:auth_app/screens/cercle_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'create_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final AuthService _authService = AuthService();
  final Color _accentColor = const Color(0xFFDA7756);
  final user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _cercles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    if (user != null) {
      fetchUserCercles(); // Cargar los círculos al inicio
    }
  }

  // Método para obtener los círculos del usuario
  Future<void> fetchUserCercles() async {
    final response = await Supabase.instance.client
        .from('usuarios_cercles')
        .select('cercle_id, cercles(id, nombre, descripcion, user_id, publicaciones(count))')
        .eq('user_id', user!.id);

    setState(() {
      _cercles = response;
      _isLoading = false;
    });
  }

  // Método para mostrar el bottom sheet con los círculos
  void _showMorePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // Para que se ajuste el tamaño según el contenido
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.25, // 1/4 de la pantalla
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Mis Círculos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cercles.isEmpty
                      ? const Text(
                          'No perteneces a ningún círculo.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _cercles.length,
                            itemBuilder: (context, index) {
                              final item = _cercles[index];
                              final cercle = item['cercles'];
                              final postCount = cercle['publicaciones'][0]['count'] ?? 0;

                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.group),
                                    title: Text(
                                      cercle['nombre'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${cercle['descripcion'] ?? ''}\nPublicaciones: $postCount',
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CercleDetailScreen(cercle: cercle),
                                        ),
                                      );
                                    },
                                  ),
                                  // Línea de separación
                                  const Divider(),
                                ],
                              );
                            },
                          ),
                        ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar el bottom sheet
                },
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
    final List<Widget> screens = [
      HomeScreen(username: widget.username, showMenu: false),
      const DiscoverScreen(),
      const CreateScreen(),
      const Center(child: Text('Más')), // Nueva pantalla de "Más" solo como placeholder
      ProfileScreen(username: widget.username),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _signOut(context),
            color: Colors.grey[800],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            // Cuando el usuario toque "Más", abre el bottom sheet
            _showMorePopup(context);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Descubrir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more),
            label: 'Más',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Descubrir';
      case 2:
        return 'Crear';
      case 3:
        return 'Más';
      case 4:
        return 'Perfil';
      default:
        return '';
    }
  }
}
