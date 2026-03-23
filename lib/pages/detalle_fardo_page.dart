import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'editar_fardo_page.dart';

class DetalleFardoPage extends StatefulWidget {
  final Map<String, dynamic> fardo;

  const DetalleFardoPage({super.key, required this.fardo});

  @override
  State<DetalleFardoPage> createState() => _DetalleFardoPageState();
}

class _DetalleFardoPageState extends State<DetalleFardoPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> detalles = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      await _cargarFardo();
      await _cargarDetalles();
    } catch (e) {
      print("ERROR al cargar: $e");
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  Future<void> _cargarFardo() async {
    final id = widget.fardo['id'] as int;
    final data = await db.getFardoById(id);

    if (data != null) {
      widget.fardo['tipo'] = data['tipo'];
      widget.fardo['costo_total'] = data['costo_total'];
      widget.fardo['fecha_compra'] = data['fecha_compra'];
    }
  }

  Future<void> _cargarDetalles() async {
    final raw = await db.getDetallesFardo(widget.fardo['id'] as int);

    detalles = raw.map((d) {
      return {
        "id": d["id"],
        "fardo_id": d["fardo_id"],
        "prenda_id": d["prenda_id"],
        "prenda_nombre": d["prenda_nombre"] ?? "Sin nombre",
        "cantidad_inicial":
            int.tryParse(d["cantidad_inicial"].toString()) ?? 0,
        "precio_referencial":
            double.tryParse(d["precio_referencial"].toString()) ?? 0.0,
      };
    }).toList();

    if (mounted) setState(() {});
  }

  Future<void> _eliminarFardo() async {
    final id = widget.fardo['id'];

    final conn = await db.database;
    await conn.delete("fardo_detalles", where: "fardo_id = ?", whereArgs: [id]);
    await conn.delete("fardos", where: "id = ?", whereArgs: [id]);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ==========================================================
  // ESTILO TARJETA – PURA PINTA
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
    final f = widget.fardo;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          "Detalle del Fardo",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF8C3A50)),
            onPressed: () async {
              final actualizado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarFardoPage(fardo: widget.fardo),
                ),
              );

              if (actualizado == true) {
                setState(() => cargando = true);
                await _cargarTodo();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmar = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Eliminar Fardo"),
                  content:
                      const Text("¿Seguro que querés eliminar este fardo?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Eliminar"),
                    ),
                  ],
                ),
              );

              if (confirmar == true) _eliminarFardo();
            },
          ),
        ],
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------------
                  // ENCABEZADO
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardBox(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tipo: ${f['tipo']}",
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4740),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Costo Total: Bs ${f['costo_total']}",
                          style: const TextStyle(
                            color: Color(0xFF8C3A50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Fecha de compra: ${f['fecha_compra']}",
                          style: const TextStyle(
                            color: Color(0xFF5A4740),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Prendas del Fardo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4740),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --------------------------------------------------
                  // LISTA DE PRENDAS
                  // --------------------------------------------------
                  Expanded(
                    child: detalles.isEmpty
                        ? const Text(
                            "Este fardo no tiene prendas registradas.",
                            style: TextStyle(color: Color(0xFF5A4740)),
                          )
                        : ListView.builder(
                            itemCount: detalles.length,
                            itemBuilder: (_, i) {
                              final d = detalles[i];
                              final precio =
                                  (d['precio_referencial'] ?? 0.0) as double;

                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: _cardBox(),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.checkroom,
                                      size: 32,
                                      color: Color(0xFF8C3A50),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['prenda_nombre'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF5A4740),
                                            ),
                                          ),
                                          Text(
                                            "Cantidad: ${d['cantidad_inicial']} unidades",
                                            style: const TextStyle(
                                              color: Color(0xFF8C3A50),
                                            ),
                                          ),
                                          Text(
                                            "Precio referencial: Bs ${precio.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5A4740),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
