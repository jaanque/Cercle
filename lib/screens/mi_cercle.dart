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
    });
  }

  Future<void> eliminarCercle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _cercle == null || _cercle!['user_id'] != user.id) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar Cercle?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client
        .from('usuarios_cercles')
        .delete()
        .eq('cercle_id', _cercle!['id']);

    await Supabase.instance.client
        .from('cercles')
        .delete()
        .eq('id', _cercle!['id']);

    setState(() {
      _cercle = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cercle eliminado')),
    );
  }

  Future<void> abandonarCercle() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _cercle == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Abandonar Cercle?'),
        content: const Text('¿Seguro que deseas abandonar este cercle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abandonar')),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client
        .from('usuarios_cercles')
        .delete()
        .eq('user_id', user.id)
        .eq('cercle_id', _cercle!['id']);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Has abandonado el cercle')),
    );

    // Redirigir al usuario a DiscoverScreen
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DiscoverScreen()),
        (route) => false,
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
            if (_isCreator)
              ElevatedButton.icon(
                onPressed: eliminarCercle,
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar Cercle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: abandonarCercle,
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
