import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'nuevo_fardo_page.dart';
import 'detalle_fardo_page.dart';

class FardosPage extends StatefulWidget {
  const FardosPage({super.key});

  @override
  State<FardosPage> createState() => _FardosPageState();
}

class _FardosPageState extends State<FardosPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> fardos = [];

  @override
  void initState() {
    super.initState();
    _cargarFardos();
  }

  Future<void> _cargarFardos() async {
    final data = await db.getFardos();
    setState(() => fardos = data);
  }

  // ==========================================================
  // ESTILO TARJETA – MISMO LOOK & FEEL DE PURA PINTA
  // ==========================================================
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
        )
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
          "Fardos",
          style: TextStyle(
            color: Color(0xFF5A4740),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8C3A50),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevoFardoPage()),
          ).then((_) => _cargarFardos());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: fardos.isEmpty
          ? const Center(
              child: Text(
                "No hay fardos registrados",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF5A4740),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: fardos.length,
              itemBuilder: (_, i) {
                final f = fardos[i];

                final cleanFardo = {
                  "id": int.tryParse(f["id"].toString()) ?? f["id"],
                  "tipo": f["tipo"],
                  "costo_total": f["costo_total"],
                  "fecha_compra": f["fecha_compra"],
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardBox(),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2,
                        size: 36, color: Color(0xFF8C3A50)),

                    title: Text(
                      cleanFardo['tipo'] ?? "Sin tipo",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A4740),
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Costo: Bs ${cleanFardo['costo_total']}",
                          style: const TextStyle(color: Color(0xFF8C3A50)),
                        ),
                        Text(
                          "Compra: ${cleanFardo['fecha_compra']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A4740),
                          ),
                        ),
                      ],
                    ),

                    trailing: const Icon(Icons.chevron_right,
                        size: 28, color: Color(0xFF8C3A50)),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleFardoPage(fardo: cleanFardo),
                        ),
                      ).then((_) => _cargarFardos());
                    },
                  ),
                );
              },
            ),
    );
  }
}
