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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descubrir cercles públicos')),
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
                              title: Text(cercle['nombre'] ?? 'Sin nombre'),
                              subtitle: Text(cercle['descripcion'] ?? ''),
                              leading: const Icon(Icons.public),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
