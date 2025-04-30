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
  final Color _coral = const Color(0xFFDA7756);

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
            style: ElevatedButton.styleFrom(backgroundColor: _coral),
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cercle...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredCercles.isEmpty
                      ? const Center(child: Text('No se encontraron cercles.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCercles.length,
                          itemBuilder: (context, index) {
                            final cercle = _filteredCercles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: _coral.withOpacity(0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: _coral, width: 4),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.groups_2, color: _coral, size: 20),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            cercle['nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                        if (cercle['is_verified'] == true)
                                          Icon(Icons.verified, color: _coral, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cercle['descripcion'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _intentarUnirse(cercle),
                                        style: TextButton.styleFrom(
                                          foregroundColor: _coral,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            side: BorderSide(color: _coral),
                                          ),
                                          textStyle: const TextStyle(fontSize: 13.5),
                                        ),
                                        child: const Text('Unirse'),
                                      ),
                                    ),
                                  ],
                                ),
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