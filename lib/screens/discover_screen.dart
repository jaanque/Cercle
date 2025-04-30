import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<dynamic> _cercles = [];
  List<dynamic> _filteredCercles = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCerclesPublicos();
    _searchController.addListener(_filterCercles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCerclesPublicos() async {
    final response = await Supabase.instance.client
        .from('cercles')
        .select()
        .eq('visibilidad', 'publico')
        .order('creado_en', ascending: false);

    setState(() {
      _cercles = response;
      _filteredCercles = response;
      _isLoading = false;
    });
  }

  void _filterCercles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCercles = _cercles.where((cercle) {
        final nombre = (cercle['nombre'] ?? '').toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  Future<void> unirseACercle(String userId, String cercleId) async {
    await Supabase.instance.client.from('usuarios_cercles').insert({
      'user_id': userId,
      'cercle_id': cercleId,
    });
  }

  void _intentarUnirse(Map<String, dynamic> cercle) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    // Verificar si el usuario ya está en el cercle
    final yaEsMiembro = await Supabase.instance.client
        .from('usuarios_cercles')
        .select()
        .eq('user_id', user.id)
        .eq('cercle_id', cercle['id'])
        .maybeSingle();

    if (yaEsMiembro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya eres miembro de este cercle.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar unión'),
        content: Text('¿Seguro que deseas unirte al cercle "${cercle['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDA7756),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await unirseACercle(user.id, cercle['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te has unido al cercle exitosamente.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar cercle',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredCercles.isEmpty
                      ? const Center(child: Text('No se encontraron cercles.'))
                      : ListView.builder(
                          itemCount: _filteredCercles.length,
                          itemBuilder: (context, index) {
                            final cercle = _filteredCercles[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  Text(cercle['nombre'] ?? 'Sin nombre'),
                                  if (cercle['is_verified'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: Icon(
                                        Icons.verified,
                                        color: Color(0xFFDA7756),
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(cercle['descripcion'] ?? ''),
                              leading: const Icon(Icons.public),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDA7756),
                                ),
                                onPressed: () => _intentarUnirse(cercle),
                                child: const Text('Unirse'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}