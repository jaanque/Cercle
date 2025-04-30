import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFFE87F65);

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (res.user != null) {
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. Por favor inicia sesión.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${error.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 60,
                    color: _primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Únete a Cercle',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Nombre de usuario',
                    hintText: 'Tu nombre en Cercle',
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateUsername,
                  ),
                  const SizedBox(height: 16),
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
                    hintText: 'Crea una contraseña segura',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirmar contraseña',
                    hintText: 'Vuelve a escribir tu contraseña',
                    prefixIcon: Icons.lock_reset_outlined,
                    obscureText: true,
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
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
                              'Registrarse',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
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
