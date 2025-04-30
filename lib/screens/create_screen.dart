import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  String _visibilidad = 'publico';
  bool _isLoading = false;

  final Color _accentColor = const Color(0xFFDA7756);

  Future<void> crearCercle() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Usuario no autenticado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nombreExiste = await Supabase.instance.client
          .from('cercles')
          .select('id')
          .eq('nombre', _nombreController.text.trim())
          .maybeSingle();

      if (nombreExiste != null) {
        _showErrorSnackBar('El nombre del cercle ya existe.');
        return;
      }

      final insertResponse = await Supabase.instance.client
          .from('cercles')
          .insert({
            'nombre': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'visibilidad': _visibilidad,
            'user_id': user.id,
          })
          .select()
          .single();

      final cercleId = insertResponse['id'];

      await Supabase.instance.client.from('usuarios_cercles').insert({
        'user_id': user.id,
        'cercle_id': cercleId,
      });

      _showSuccessSnackBar('Cercle creado y unido exitosamente');
      _clearForm();
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _clearForm() {
    _nombreController.clear();
    _descripcionController.clear();
    setState(() => _visibilidad = 'publico');
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _accentColor),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear un nouveau cercle',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: _inputDecoration('Nombre', Icons.add_circle_outline),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Introduce un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: _inputDecoration('Descripción', Icons.description),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Introduce una descripción' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _visibilidad,
                  decoration: _inputDecoration('Visibilidad', Icons.visibility),
                  items: const [
                    DropdownMenuItem(value: 'publico', child: Text('Público')),
                    DropdownMenuItem(value: 'privado', child: Text('Privado')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _visibilidad = value);
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : crearCercle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Crear Cercle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}