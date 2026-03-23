import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PrendasPage extends StatefulWidget {
  const PrendasPage({super.key});

  @override
  State<PrendasPage> createState() => _PrendasPageState();
}

class _PrendasPageState extends State<PrendasPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> prendas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPrendas();
  }

  Future<void> _cargarPrendas() async {
    try {
      final data = await db.getPrendas();
      if (!mounted) return;
      setState(() {
        prendas = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar prendas: $e')),
      );
    }
  }

  // ==============================
  // ESTILOS PURA PINTA
  // ==============================
  BoxDecoration _cardBox() {
    return BoxDecoration(
      color: const Color(0xFFFFF9F2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF8C3A50), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(2, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          'Prendas en tienda',
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : prendas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay prendas registradas todavía',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5A4740),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: prendas.length,
                  itemBuilder: (_, i) {
                    final p = prendas[i];
                    final nombre = (p['nombre'] ?? '').toString();
                    final stock = (p['stock_total'] ?? 0).toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardBox(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.checkroom,
                            color: Color(0xFF8C3A50),
                            size: 34,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre.isEmpty ? 'Sin nombre' : nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF5A4740),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stock: $stock unidades',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8C3A50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
