import 'package:flutter/material.dart';
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
    final List<Widget> screens = [
      HomeScreen(username: widget.username, showMenu: false),
      const DiscoverScreen(),
      const CreateScreen(),
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
        onTap: (index) => setState(() => _selectedIndex = index),
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
        return 'Perfil';
      default:
        return '';
    }
  }
}