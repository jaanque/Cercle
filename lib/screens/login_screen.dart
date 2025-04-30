import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFFE87F65);

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        if (!mounted) return;

        String? username;
        try {
          username = await _authService.getUsernameById(res.user!.id);
        } catch (_) {
          username = res.user!.email?.split('@')[0] ?? 'Usuario';
        }

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(username: username ?? 'Usuario'),
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        String message = error.message.contains('Invalid login credentials')
            ? 'Credenciales inválidas. Verifica tu correo y contraseña.'
            : error.message;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.camera_alt_outlined, size: 60, color: _primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido a Cercle',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Correo electrónico',
                    hintText: 'ejemplo@mail.com',
                    prefixIcon: Icons.mail_outline,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: _primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Iniciar sesión',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
