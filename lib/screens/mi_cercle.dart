import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'discover_screen.dart'; // Asegúrate que la ruta sea correcta

class MiCercleScreen extends StatefulWidget {
  const MiCercleScreen({super.key});

  @override
  State<MiCercleScreen> createState() => _MiCercleScreenState();
}

class _MiCercleScreenState extends State<MiCercleScreen> {
  Map<String, dynamic>? _cercle;
  bool _isCreator = false;
  bool _loading = true;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _visibilidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarCercle();
  }

  Future<void> cargarCercle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userCercle = await Supabase.instance.client
        .from('usuarios_cercles')
        .select('cercle_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (userCercle == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final cercleId = userCercle['cercle_id'];

    final cercleData = await Supabase.instance.client
        .from('cercles')
        .select()
        .eq('id', cercleId)
        .maybeSingle();

    if (cercleData != null && cercleData['user_id'] == user.id) {
      _isCreator = true;
    }

    setState(() {
      _cercle = cercleData;
      _loading = false;
      if (_cercle != null) {
        _nombreController.text = _cercle!['nombre'];
        _descripcionController.text = _cercle!['descripcion'];
        _visibilidadController.text = _cercle!['visibilidad'];
      }
    });
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _cercle == null || _cercle!['user_id'] != user.id) return;

    final response = await Supabase.instance.client
        .from('cercles')
        .update({
          'nombre': _nombreController.text,
          'descripcion': _descripcionController.text,
          'visibilidad': _visibilidadController.text,
        })
        .eq('id', _cercle!['id'])
        .single();

    if (response != null) {
      setState(() {
        _cercle = response;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cercle == null) {
      return const Scaffold(body: Center(child: Text('No estás en ningún cercle.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Cercle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${_cercle!['nombre']}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Descripción: ${_cercle!['descripcion']}'),
            const SizedBox(height: 8),
            Text('Visibilidad: ${_cercle!['visibilidad']}'),
            const SizedBox(height: 24),

            if (_isCreator) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre no puede estar vacío';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva descripción',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La descripción no puede estar vacía';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _visibilidadController.text.isNotEmpty ? _visibilidadController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Nueva visibilidad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'publico', child: Text('Público')),
                        DropdownMenuItem(value: 'privado', child: Text('Privado')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _visibilidadController.text = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La visibilidad no puede estar vacía';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_isCreator)
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica para eliminar el cercle
                },
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar Cercle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica para abandonar el cercle
                },
                icon: const Icon(Icons.logout),
                label: const Text('Abandonar Cercle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}