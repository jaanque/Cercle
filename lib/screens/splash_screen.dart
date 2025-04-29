import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // Usuario no autenticado, ir a la pantalla de onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.circle,
                  size: 120,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Cercle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}