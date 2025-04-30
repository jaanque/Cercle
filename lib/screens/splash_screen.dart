import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
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
      final user = _authService.currentUser;
      if (user != null) {
        String username;
        try {
          if (user.userMetadata != null && user.userMetadata!.containsKey('username')) {
            username = user.userMetadata!['username'] as String;
          } else {
            final data = await supabase
                .from('profiles')
                .select('username')
                .eq('id', user.id)
                .maybeSingle();
            username = data != null ? data['username'] as String : 'Usuario';
          }
        } catch (e) {
          username = user.email?.split('@')[0] ?? 'Usuario';
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainScreen(username: username),
            ),
          );
        }
      }
    } else {
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
      backgroundColor: const Color(0xFFda7756),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Donut de color blanc crema
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFf5f1e3), // Blanc crema
                  width: 30, // Gruix del cercle
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cercle',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: Color(0xFFf5f1e3), // Blanc crema per al text
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
