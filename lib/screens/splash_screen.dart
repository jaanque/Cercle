import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      // Usuario ya está autenticado
      final user = _authService.currentUser;
      if (user != null) {
        String username;
        try {
          // Intentar obtener username de metadata primero
          if (user.userMetadata != null && user.userMetadata!.containsKey('username')) {
            username = user.userMetadata!['username'] as String;
          } else {
            // Si no está en metadata, intentar obtenerlo de la tabla de perfiles
            final data = await supabase
                .from('profiles')
                .select('username')
                .eq('id', user.id)
                .maybeSingle();
            username = data != null ? data['username'] as String : 'Usuario';
          }
        } catch (e) {
          print("Error al obtener username: $e");
          // Usar correo electrónico como alternativa o un valor predeterminado
          username = user.email?.split('@')[0] ?? 'Usuario';
        }
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(username: username),
            ),
          );
        }
      }
    } else {
      // Usuario no autenticado, ir a login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Cargando...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}