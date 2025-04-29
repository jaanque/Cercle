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

  Future<void> crearCercle() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Usuario no autenticado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existing = await Supabase.instance.client
          .from('cercles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        _showErrorSnackBar('Ya has creado un cercle. Solo puedes crear uno.');
        return;
      }

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _clearForm() {
    _nombreController.clear();
    _descripcionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cercle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce una descripción'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibilidad,
                items: const [
                  DropdownMenuItem(value: 'publico', child: Text('Público')),
                  DropdownMenuItem(value: 'privado', child: Text('Privado')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _visibilidad = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Visibilidad',
                  prefixIcon: Icon(Icons.visibility),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : crearCercle,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Crear Cercle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
