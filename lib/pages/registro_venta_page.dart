import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegistroVentaPage extends StatefulWidget {
  const RegistroVentaPage({super.key});

  @override
  State<RegistroVentaPage> createState() => _RegistroVentaPageState();
}

class _RegistroVentaPageState extends State<RegistroVentaPage> {
  final db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> prendas = [];
  String? prendaSeleccionada;

  final cantidadController = TextEditingController();
  final precioController = TextEditingController();
  final nombreClienteController = TextEditingController();
  final celularClienteController = TextEditingController();

  List<Map<String, dynamic>> carrito = [];

  double get totalCarrito {
    return carrito.fold<double>(
      0.0,
      (sum, item) => sum + (item['subtotal'] as double),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarPrendas();
  }

  Future<void> _cargarPrendas() async {
    final data = await db.getPrendas();
    setState(() => prendas = data);
  }

  void _agregarAlCarrito() {
    if (prendaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una prenda')),
      );
      return;
    }

    final cantidad = int.tryParse(cantidadController.text.trim()) ?? 0;
    final totalLinea = double.tryParse(precioController.text.trim()) ?? 0.0;

    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }

    if (totalLinea <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio total inválido')),
      );
      return;
    }

    final prenda = prendas.firstWhere(
      (p) => p['nombre'] == prendaSeleccionada,
      orElse: () => {},
    );

    if (prenda.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener la prenda seleccionada')),
      );
      return;
    }

    final prendaId = prenda['id'] as int;
    final nombre = prenda['nombre'] as String;
    final precioUnitario = totalLinea / cantidad;

    setState(() {
      carrito.add({
        'prenda_id': prendaId,
        'prenda_nombre': nombre,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'subtotal': totalLinea,
      });

      cantidadController.clear();
      precioController.clear();
      prendaSeleccionada = null;
    });
  }

  Future<void> _guardarVenta() async {
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una prenda al carrito')),
      );
      return;
    }

    final clienteNombre = nombreClienteController.text.trim();
    final clienteCelular = celularClienteController.text.trim();

    final total = totalCarrito;
    final now = DateTime.now().toIso8601String();

    final ventaId = await db.insertVenta({
      'cliente_nombre': clienteNombre,
      'cliente_celular': clienteCelular,
      'total_venta': total,
      'sincronizado': 0,
      'created_at': now,
      'updated_at': now,
    });

    for (final item in carrito) {
      final int prendaId = item['prenda_id'] as int;
      final cantidad = item['cantidad'] as int;
      final precioUnit = item['precio_unitario'] as double;
      final subtotal = item['subtotal'] as double;

      await db.insertDetalleVenta({
        'venta_id': ventaId,
        'prenda_id': prendaId,
        'cantidad': cantidad,
        'precio_unitario': precioUnit,
        'subtotal': subtotal,
        'sincronizado': 0,
        'created_at': now,
        'updated_at': now,
      });

      await db.restarStock(prendaId, cantidad);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Venta registrada con éxito')),
    );

    Navigator.pop(context, true);
  }

  // ================================================================
  // ESTILOS BOUTIQUE PURA PINTA
  // ================================================================

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF6EDE3),
      labelStyle: const TextStyle(
        color: Color(0xFF5A4740),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8C3A50), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF5A4740), width: 2),
      ),
    );
  }

  BoxDecoration _cardBox() {
    return BoxDecoration(
      color: const Color(0xFFFFF9F2),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF8C3A50), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8,
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
        title: const Text(
          'Registrar venta',
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      //--------------------------------------------------------------------
      // 🛍 CONTENIDO
      //--------------------------------------------------------------------
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //--------------------------------------------------------------------
              // CARD 1: AGREGAR PRODUCTOS
              //--------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "👜 Agregar productos al carrito",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8C3A50),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: prendaSeleccionada,
                      decoration: _inputDeco("Selecciona una prenda"),
                      items: prendas
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['nombre'] as String,
                              child: Text(p['nombre'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => prendaSeleccionada = val),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco("Cantidad"),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: precioController,
                      keyboardType: TextInputType.number,
                      decoration:
                          _inputDeco("Precio total de esta línea (Bs)"),
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _agregarAlCarrito,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text("Agregar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C3A50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              //--------------------------------------------------------------------
              // CARD 2: CARRITO
              //--------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🛍 Carrito",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8C3A50),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (carrito.isEmpty)
                      const Text(
                        "No hay productos agregados",
                        style: TextStyle(color: Color(0xFF5A4740)),
                      ),

                    if (carrito.isNotEmpty)
                      ...carrito.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6EDE3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.checkroom,
                                  size: 32, color: Color(0xFF8C3A50)),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['prenda_nombre'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5A4740),
                                      ),
                                    ),
                                    Text(
                                      "${item['cantidad']} x Bs ${item['precio_unitario'].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          color: Color(0xFF5A4740)),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "Bs ${item['subtotal']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8C3A50)),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    setState(() => carrito.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      }),

                    if (carrito.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Total: Bs ${totalCarrito.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8C3A50),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 22),

              //--------------------------------------------------------------------
              // CARD 3: CLIENTE
              //--------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "👤 Datos del cliente (opcional)",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8C3A50),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: nombreClienteController,
                      decoration: _inputDeco("Nombre del cliente"),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: celularClienteController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDeco("Nro. celular"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              //--------------------------------------------------------------------
              // BOTÓN FINAL
              //--------------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarVenta,
                  icon: const Icon(Icons.check),
                  label: const Text(
                    "Confirmar venta",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3A50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
