import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'create_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'mi_cercle.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
    // Lista de pantallas para mostrar - reordenada para coincidir con la barra de navegación
    final List<Widget> screens = [
      HomeScreen(username: widget.username, showMenu: false),
      const DiscoverScreen(),
      const CreateScreen(), // Movida a la posición central
      const MiCercleScreen(),
      ProfileScreen(username: widget.username), // Perfil movido a la derecha del todo
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Descubrir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Mi Cercle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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
        return 'Mi Cercle';
      case 4:
        return 'Perfil';
      default:
        return '';
    }
  }
}