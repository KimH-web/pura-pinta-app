import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NuevoFardoPage extends StatefulWidget {
  const NuevoFardoPage({super.key});

  @override
  State<NuevoFardoPage> createState() => _NuevoFardoPageState();
}

class _NuevoFardoPageState extends State<NuevoFardoPage> {
  final formKey = GlobalKey<FormState>();
  final db = DatabaseHelper();

  String tipoFardo = "Normal";

  final TextEditingController costoController = TextEditingController();

  int? prendaSeleccionadaNormal;
  final TextEditingController cantidadNormal = TextEditingController();
  final TextEditingController prendaNuevaNormal = TextEditingController();

  List<Map<String, dynamic>> prendasExistentes = [];

  List<Map<String, dynamic>> prendasMixtas = [];
  bool mostrarFormMixto = false;

  int? prendaSeleccionadaMixto;
  final TextEditingController cantidadMixto = TextEditingController();
  final TextEditingController prendaNuevaMixto = TextEditingController();

  // ============================================================
  // Cargar prendas
  // ============================================================
  Future<void> cargarPrendas() async {
    final all = await db.getPrendas();

    final nombres = <String>{};
    prendasExistentes = all.where((p) {
      final nombre = (p['nombre'] ?? '').toString();
      if (nombres.contains(nombre)) return false;
      nombres.add(nombre);
      return true;
    }).toList();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cargarPrendas();
  }

  // ============================================================
  // Guardar fardo
  // ============================================================
  Future<void> guardarFardo() async {
    if (!formKey.currentState!.validate()) return;

    final double costoTotal = double.tryParse(costoController.text) ?? 0;

    int totalPrendas = 0;
    if (tipoFardo == "Normal") {
      totalPrendas = int.tryParse(cantidadNormal.text) ?? 0;
    } else {
      for (var p in prendasMixtas) {
        totalPrendas += p["cantidad"] as int;
      }
    }

    if (totalPrendas <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes ingresar al menos 1 prenda.")),
      );
      return;
    }

    final double precioUnitario =
        costoTotal > 0 ? costoTotal / totalPrendas : 0;

    final now = DateTime.now().toIso8601String();

    final int fardoId = await db.insertFardo({
      "tipo": tipoFardo,
      "costo_total": costoTotal,
      "fecha_compra": now,
      "created_at": now,
      "updated_at": now,
    });

    // ------------------------
    // Fardo NORMAL
    // ------------------------
    if (tipoFardo == "Normal") {
      final int cantidad = int.tryParse(cantidadNormal.text) ?? 0;

      if (cantidad <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cantidad inválida.")),
        );
        return;
      }

      final String nombreNueva = prendaNuevaNormal.text.trim();

      if (prendaSeleccionadaNormal == null && nombreNueva.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seleccione una prenda o ingrese una nueva."),
          ),
        );
        return;
      }

      int prendaId;

      if (prendaSeleccionadaNormal != null) {
        prendaId = prendaSeleccionadaNormal!;
        await db.sumarStock(prendaId, cantidad);
      } else {
        prendaId = await db.getOrCreatePrenda(nombreNueva);
        await db.sumarStock(prendaId, cantidad);
      }

      await db.insertDetalleFardo({
        "fardo_id": fardoId,
        "prenda_id": prendaId,
        "Cantidad_inicial": cantidad,
        "precio_referencial": precioUnitario,
        "created_at": now,
        "updated_at": now,
      });
    }

    // ------------------------
    // Fardo MIXTO
    // ------------------------
    else {
      if (prendasMixtas.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Agrega al menos una prenda al fardo mixto."),
          ),
        );
        return;
      }

      for (var item in prendasMixtas) {
        int prendaId = item["id"] as int;
        final String nombre = (item["nombre"] as String).trim();
        final int cantidad = item["cantidad"] as int;

        if (cantidad <= 0) continue;

        if (prendaId == 0) {
          prendaId = await db.getOrCreatePrenda(nombre);
        }

        await db.sumarStock(prendaId, cantidad);

        await db.insertDetalleFardo({
          "fardo_id": fardoId,
          "prenda_id": prendaId,
          "cantidad_inicial": cantidad,
          "precio_referencial": precioUnitario,
          "created_at": now,
          "updated_at": now,
        });
      }
    }

    await cargarPrendas();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // ============================================================
  // ESTILO PURA PINTA
  // ============================================================
  InputDecoration _decor(String label) {
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
        borderSide:
            const BorderSide(color: Color(0xFF8C3A50), width: 2),
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

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          "Nuevo Fardo",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // Tipo de fardo
              // ------------------------------------------------
              DropdownButtonFormField<String>(
                value: tipoFardo,
                decoration: _decor("Tipo de fardo"),
                items: const [
                  DropdownMenuItem(value: "Normal", child: Text("Normal")),
                  DropdownMenuItem(value: "Mixto", child: Text("Mixto")),
                ],
                onChanged: (v) => setState(() => tipoFardo = v!),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // Costo total
              // ------------------------------------------------
              TextFormField(
                controller: costoController,
                keyboardType: TextInputType.number,
                decoration: _decor("Costo total del fardo (Bs)"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? "Debe ingresar un costo"
                        : null,
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // Fardo NORMAL
              // ------------------------------------------------
              if (tipoFardo == "Normal") ...[
                const Text(
                  "Seleccione prenda existente",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4740),
                  ),
                ),
                const SizedBox(height: 6),

                DropdownButtonFormField<int?>(
                  value: prendaSeleccionadaNormal,
                  decoration: _decor("Prenda"),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("-- Ninguna --")),
                    ...prendasExistentes.map(
                      (p) => DropdownMenuItem(
                        value: p["id"] as int,
                        child: Text(p["nombre"] as String),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      prendaSeleccionadaNormal = v;
                      if (v != null) prendaNuevaNormal.clear();
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: prendaNuevaNormal,
                  enabled: prendaSeleccionadaNormal == null,
                  decoration: _decor("Nueva prenda"),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: cantidadNormal,
                  keyboardType: TextInputType.number,
                  decoration: _decor("Cantidad"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? "Necesario"
                          : null,
                ),
              ],

              // ------------------------------------------------
              // Fardo MIXTO
              // ------------------------------------------------
              if (tipoFardo == "Mixto") ...[
                const Text(
                  "Prendas del fardo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4740),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                if (prendasMixtas.isEmpty)
                  const Text("No hay prendas agregadas"),

                ...prendasMixtas.map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: _cardBox(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p["nombre"],
                          style: const TextStyle(
                            color: Color(0xFF5A4740),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("${p["cantidad"]} u"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
                  onPressed: () =>
                      setState(() => mostrarFormMixto = !mostrarFormMixto),
                ),

                if (mostrarFormMixto) ...[
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int?>(
                    value: prendaSeleccionadaMixto,
                    decoration: _decor("Prenda existente"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("-- Ninguna --")),
                      ...prendasExistentes.map(
                        (p) => DropdownMenuItem(
                          value: p["id"] as int,
                          child: Text(p["nombre"] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        prendaSeleccionadaMixto = v;
                        if (v != null) prendaNuevaMixto.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: prendaNuevaMixto,
                    enabled: prendaSeleccionadaMixto == null,
                    decoration: _decor("Nueva prenda"),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: cantidadMixto,
                    keyboardType: TextInputType.number,
                    decoration: _decor("Cantidad"),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C3A50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final int cant =
                          int.tryParse(cantidadMixto.text.trim()) ?? 0;
                      final String nombreNueva = prendaNuevaMixto.text.trim();

                      if (cant <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cantidad inválida.")),
                        );
                        return;
                      }

                      if (prendaSeleccionadaMixto == null &&
                          nombreNueva.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Seleccione una prenda o escriba una nueva."),
                          ),
                        );
                        return;
                      }

                      int id = prendaSeleccionadaMixto ?? 0;
                      String nombre;

                      if (id != 0) {
                        final prendaMap = prendasExistentes.firstWhere(
                          (p) => p["id"] == id,
                          orElse: () => {},
                        );
                        nombre = (prendaMap["nombre"] ?? "") as String;
                      } else {
                        nombre = nombreNueva;
                      }

                      setState(() {
                        prendasMixtas.add({
                          "id": id,
                          "nombre": nombre,
                          "cantidad": cant,
                        });

                        prendaSeleccionadaMixto = null;
                        prendaNuevaMixto.clear();
                        cantidadMixto.clear();
                        mostrarFormMixto = false;
                      });
                    },
                    child: const Text("Agregar prenda"),
                  ),
                ],
              ],

              const SizedBox(height: 30),

              // ------------------------------------------------
              // GUARDAR FARDOS
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C3A50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: guardarFardo,
                  child: const Text(
                    "Guardar Fardo",
                    style: TextStyle(fontSize: 16),
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
