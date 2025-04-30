import 'dart:math';

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
  final TextEditingController _codigoController = TextEditingController();  // Agregado controlador para código
  String _visibilidad = 'publico';
  bool _isLoading = false;

  final Color _accentColor = const Color(0xFFDA7756);

  // Función para crear un cercle
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

      // Generar código aleatorio alfanumérico
      String codigoCercle = _generarCodigoAleatorio();

      // Verificar que el código generado no exista
      final codigoExiste = await Supabase.instance.client
          .from('cercles')
          .select('id')
          .eq('codigo_cercle', codigoCercle)
          .maybeSingle();

      if (codigoExiste != null) {
        _showErrorSnackBar('Código de cercle ya existe. Intenta de nuevo.');
        return;
      }

      // Insertar el cercle
      final insertResponse = await Supabase.instance.client
          .from('cercles')
          .insert({
            'nombre': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'visibilidad': _visibilidad,
            'user_id': user.id,
            'codigo_cercle': codigoCercle, // Guardar el código en la base de datos
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

  // Función para unirse a un cercle con un código
  Future<void> unirseACercle(String codigo) async {
    if (codigo.trim().isEmpty) {
      _showErrorSnackBar('Por favor, ingresa un código');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Usuario no autenticado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar si el código es válido
      final cercleResponse = await Supabase.instance.client
          .from('cercles')
          .select('id')
          .eq('codigo_cercle', codigo.trim())
          .maybeSingle();

      if (cercleResponse == null) {
        _showErrorSnackBar('Código de cercle inválido');
        return;
      }

      final cercleId = cercleResponse['id'];

      // Verificar si el usuario ya pertenece al cercle
      final userCercleResponse = await Supabase.instance.client
          .from('usuarios_cercles')
          .select('user_id')
          .eq('user_id', user.id)
          .eq('cercle_id', cercleId)
          .maybeSingle();

      if (userCercleResponse != null) {
        _showErrorSnackBar('Ya eres miembro de este cercle');
        return;
      }

      // Unir al usuario al cercle
      await Supabase.instance.client.from('usuarios_cercles').insert({
        'user_id': user.id,
        'cercle_id': cercleId,
      });

      _showSuccessSnackBar('Te has unido al cercle exitosamente');
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Generar código alfanumérico único de 9 caracteres
  String _generarCodigoAleatorio() {
    const _caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(9, (index) {
      return _caracteres[random.nextInt(_caracteres.length)];
    }).join();
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
                  'Crear un nuevo cercle',
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
                const SizedBox(height: 40),
                const Text(
                  'Unirse a un cercle con código',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoController,  // Añadido controlador para el código
                  decoration: _inputDecoration('Código del cercle', Icons.key),
                  onFieldSubmitted: (codigo) {
                    unirseACercle(codigo);
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    final codigo = _codigoController.text.trim();
                    unirseACercle(codigo);
                  },
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
                      : const Text('Unirse al Cercle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
