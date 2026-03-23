import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DetalleVentaPage extends StatefulWidget {
  final Map<String, dynamic> venta;

  const DetalleVentaPage({super.key, required this.venta});

  @override
  State<DetalleVentaPage> createState() => _DetalleVentaPageState();
}

class _DetalleVentaPageState extends State<DetalleVentaPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> detalles = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    final data = await db.getDetallesVenta(widget.venta['id']);
    if (!mounted) return;

    setState(() {
      detalles = data;
      cargando = false;
    });
  }

  Future<void> _eliminarVenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF3E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Eliminar venta",
          style: TextStyle(color: Color(0xFF8C3A50)),
        ),
        content: const Text(
          "¿Está seguro de eliminar esta venta? Se restaurará el stock de todas las prendas vendidas.",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Color(0xFF5A4740)),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await db.eliminarVenta(widget.venta['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

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
    final v = widget.venta;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          "Detalle de la venta",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // ===========================
                  // TARJETA ENCABEZADO
                  // ===========================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardBox(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cliente: ${v['cliente_nombre'] ?? 'Sin nombre'}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8C3A50),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Celular: ${v['cliente_celular'] ?? '---'}",
                          style: const TextStyle(color: Color(0xFF5A4740)),
                        ),
                        Text(
                          "Fecha: ${v['created_at'] ?? '---'}",
                          style: const TextStyle(color: Color(0xFF5A4740)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Total: Bs ${v['total_venta']}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8C3A50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Productos vendidos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4740),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===========================
                  // LISTA DE PRODUCTOS
                  // ===========================
                  ...detalles.map((d) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardBox(),
                      child: Row(
                        children: [
                          const Icon(Icons.checkroom,
                              color: Color(0xFF8C3A50), size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['prenda_nombre'] ?? "Sin nombre",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5A4740),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${d['cantidad']} × Bs ${d['precio_unitario']} = Bs ${d['subtotal']}",
                                  style: const TextStyle(
                                    color: Color(0xFF8C3A50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 40),

                  // ===========================
                  // BOTÓN ELIMINAR
                  // ===========================
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _eliminarVenta,
                    child: const Text(
                      "Eliminar venta",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
