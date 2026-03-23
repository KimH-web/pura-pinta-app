import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EditarFardoPage extends StatefulWidget {
  final Map<String, dynamic> fardo;

  const EditarFardoPage({super.key, required this.fardo});

  @override
  State<EditarFardoPage> createState() => _EditarFardoPageState();
}

class _EditarFardoPageState extends State<EditarFardoPage> {
  final db = DatabaseHelper();

  final TextEditingController costoController = TextEditingController();

  List<Map<String, dynamic>> detalles = [];
  List<Map<String, dynamic>> prendas = [];

  bool mostrarFormularioAgregar = false;

  int? prendaExistenteSeleccionada;
  final TextEditingController nuevaPrendaController = TextEditingController();
  final TextEditingController cantidadNuevaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    costoController.text = widget.fardo['costo_total'].toString();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final raw = await db.getDetallesFardo(widget.fardo['id']);

    detalles = raw.map((d) {
      return {
        "id": d["id"],
        "prenda_id": d["prenda_id"],
        "prenda_nombre": d["prenda_nombre"],
        "cantidad_inicial": int.tryParse(d["cantidad_inicial"].toString()) ?? 0,
        "precio_referencial": double.tryParse(d["precio_referencial"].toString()) ?? 0.0,
      };
    }).toList();

    prendas = await db.getPrendas();
    setState(() {});
  }

  Future<void> _agregarPrendaAlFardo() async {
    final int cantidad = int.tryParse(cantidadNuevaController.text) ?? 0;
    if (cantidad <= 0) return;

    int? prendaId;

    if (prendaExistenteSeleccionada != null) {
      prendaId = prendaExistenteSeleccionada;
    } else if (nuevaPrendaController.text.trim().isNotEmpty) {
      prendaId = await db.getOrCreatePrenda(
        nuevaPrendaController.text.trim(),
      );
    }

    if (prendaId == null) return;

    await db.insertDetalleFardo({
      "fardo_id": widget.fardo['id'],
      "prenda_id": prendaId,
      "cantidad_inicial": cantidad,
      "precio_referencial": 0,
      "created_at": DateTime.now().toString(),
      "updated_at": DateTime.now().toString(),
    });

    nuevaPrendaController.clear();
    cantidadNuevaController.clear();
    prendaExistenteSeleccionada = null;
    mostrarFormularioAgregar = false;

    await _cargarDatos();
  }

  Future<void> _guardarCambios() async {
    int totalPrendas = 0;
    for (var d in detalles) {
      totalPrendas += (d['cantidad_inicial'] as int);
    }

    if (totalPrendas == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El fardo no tiene prendas válidas.")),
      );
      return;
    }

    final double costoTotal = double.tryParse(costoController.text) ?? 0;
    final double precioUnitario = costoTotal / totalPrendas;

    for (var d in detalles) {
      await db.updateDetalleFardo(
        d['id'],
        {
          "cantidad_inicial": d['cantidad_inicial'],
          "precio_referencial": double.parse(precioUnitario.toStringAsFixed(1)),
          "updated_at": DateTime.now().toString(),
        },
      );
    }

    await db.updateFardo(widget.fardo['id'], {
      "costo_total": costoTotal,
      "updated_at": DateTime.now().toString(),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ==========================================================
  // ESTILO PURA PINTA
  // ==========================================================
  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFF9F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8C3A50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8C3A50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8C3A50), width: 2),
      ),
    );
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

  // ---------------------------------------------------------
  // NUEVO WIDGET: INFO BOX (para que el tipo NO se corte)
  // ---------------------------------------------------------
  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
  color: const Color(0xFFFFF9F2),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(
    color: const Color(0xFF8C3A50),
    width: 1,
  ),
),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8C3A50),
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4740),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String tipo = widget.fardo['tipo'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          "Editar Fardo",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // --------------------------------------------------------
            // TIPO DE FADO (REEMPLAZADO POR INFOBOX)
            // --------------------------------------------------------
            _infoBox("Tipo de fardo", tipo),

            // --------------------------------------------------------
            // COSTO DEL FADO
            // --------------------------------------------------------
            TextFormField(
              controller: costoController,
              decoration: _inputDecor("Costo total del fardo (Bs)"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 25),

            const Text(
              "Prendas en este fardo:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4740),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------------
            // LISTA EDITABLE DE PRENDAS
            // --------------------------------------------------------
            ...detalles.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: _cardBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['prenda_nombre'] ?? "Sin nombre",
                      style: const TextStyle(
                        color: Color(0xFF5A4740),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text("Cantidad:",
                            style: TextStyle(color: Color(0xFF8C3A50))),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: d['cantidad_inicial'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecor(""),
                            onChanged: (val) {
                              setState(() {
                                d['cantidad_inicial'] =
                                    int.tryParse(val) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            // --------------------------------------------------------
            // AGREGAR NUEVA PRENDA
            // --------------------------------------------------------
            if (tipo == "Mixto") ...[
              const SizedBox(height: 25),

              OutlinedButton.icon(
                icon: const Icon(Icons.add, color: Color(0xFF8C3A50)),
                label: const Text(
                  "Agregar prenda",
                  style: TextStyle(color: Color(0xFF8C3A50)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8C3A50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    mostrarFormularioAgregar = !mostrarFormularioAgregar;
                  });
                },
              ),

              if (mostrarFormularioAgregar) ...[
                const SizedBox(height: 14),

                DropdownButtonFormField<int>(
                  decoration: _inputDecor("Prenda existente"),
                  value: prendaExistenteSeleccionada,
                  items: prendas
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['nombre'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => prendaExistenteSeleccionada = v);
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: nuevaPrendaController,
                  decoration: _inputDecor("Nueva prenda (opcional)"),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: cantidadNuevaController,
                  decoration: _inputDecor("Cantidad"),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3A50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _agregarPrendaAlFardo,
                  child: const Text("Agregar prenda"),
                ),
              ],
            ],

            const SizedBox(height: 30),

            // --------------------------------------------------------
            // BOTÓN GUARDAR CAMBIOS
            // --------------------------------------------------------
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C3A50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _guardarCambios,
              child: const Text(
                "Guardar cambios",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
