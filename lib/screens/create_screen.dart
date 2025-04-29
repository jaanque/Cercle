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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verifica si el usuario ya tiene un cercle
      final existing = await Supabase.instance.client
          .from('cercles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has creado un cercle. Solo puedes crear uno.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Si no tiene, crear el cercle
      final insertResponse = await Supabase.instance.client
          .from('cercles')
          .insert({
            'nombre': _nombreController.text,
            'descripcion': _descripcionController.text,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cercle creado y unido exitosamente')),
      );

      _nombreController.clear();
      _descripcionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce un nombre'
                    : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce una descripción'
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: _visibilidad,
                items: const [
                  DropdownMenuItem(value: 'publico', child: Text('Público')),
                  DropdownMenuItem(value: 'privado', child: Text('Privado')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _visibilidad = value);
                },
                decoration: const InputDecoration(labelText: 'Visibilidad'),
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
