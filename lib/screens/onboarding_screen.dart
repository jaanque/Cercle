import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color _primaryColor = const Color(0xFFE87F65); // Naranja Cercle

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Crea o únete a un Cercle',
      description: 'Forma parte de un Cercle con tus amigos o conoce nuevas personas con intereses similares.',
      image: Icons.group_add,
    ),
    OnboardingPage(
      title: 'Comparte momentos únicos',
      description: 'Sube tus fotos y míralas reunidas en un feed compartido con los miembros de tu Cercle.',
      image: Icons.photo_library,
    ),
    OnboardingPage(
      title: 'Privado o público, tú decides',
      description: 'Haz tu Cercle público para que todos vean el feed, o privado para compartir solo con los miembros.',
      image: Icons.lock_open,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Ir a pantalla de registro al finalizar el onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Slider
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicadores de página
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),

            const SizedBox(height: 20),

            // Botón Siguiente o Empezar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Empezar' : 'Siguiente',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // Opción de iniciar sesión
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                '¿Ya tienes cuenta? Inicia sesión',
                style: TextStyle(color: _primaryColor),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.image, size: 120, color: _primaryColor),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 10,
      height: _currentPage == index ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? _primaryColor : Colors.grey.shade400,
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
