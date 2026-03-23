import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'registro_venta_page.dart';
import 'detalle_venta_page.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final db = DatabaseHelper();

  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> ventasFiltradas = [];

  bool cargando = true;

  String filtroActual = 'todas';
  int? filtroMesCustom;
  int? filtroAnioCustom;

  double totalHoy = 0;
  double totalSemana = 0;
  double totalMes = 0;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  // =====================================================
  // CARGAR VENTAS
  // =====================================================
  Future<void> _cargarVentas() async {
    try {
      final data = await db.getAllVentas();
      if (!mounted) return;

      setState(() {
        ventas = data;
        filtroActual = 'hoy';
        _aplicarFiltro(tipo: 'hoy');

        _calcularTotales();
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar ventas: $e")),
      );
    }
  }

  // =====================================================
  // CÁLCULO DE TOTALES
  // =====================================================
  void _calcularTotales() {
    final now = DateTime.now();

    totalHoy = 0;
    totalSemana = 0;
    totalMes = 0;

    for (final v in ventas) {
      final fecha = DateTime.tryParse(v['created_at'] ?? "");
      if (fecha == null) continue;

      final total = (v['total_venta'] ?? 0) * 1.0;

      if (fecha.year == now.year &&
          fecha.month == now.month &&
          fecha.day == now.day) {
        totalHoy += total;
      }

      final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
      if (fecha.isAfter(inicioSemana.subtract(const Duration(days: 1)))) {
        totalSemana += total;
      }

      if (fecha.year == now.year && fecha.month == now.month) {
        totalMes += total;
      }
    }
  }

  // =====================================================
  // FORMATOS
  // =====================================================
  String _formatearFecha(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;

    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    return '$d/$m/$y   $h:$min';
  }

  // =====================================================
  // ESTILOS PURA PINTA
  // =====================================================

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

  Widget _tarjetaDashboard(String titulo, double monto, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8C3A50), width: 0.6),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4740),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bs ${monto.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF8C3A50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // AGRUPAR MESES POR AÑO (NUEVO)
  // =====================================================
  Map<int, List<int>> _agruparMesesPorAnio() {
  final Map<int, Set<int>> mapa = {};

  for (final v in ventas) {
    final fecha = DateTime.tryParse(v['created_at'] ?? '');
    if (fecha != null) {
      mapa.putIfAbsent(fecha.year, () => <int>{});
      mapa[fecha.year]!.add(fecha.month);
    }
  }

  final aniosOrdenados = mapa.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  final Map<int, List<int>> resultado = {};

  for (final anio in aniosOrdenados) {
    final mesesOrdenados = mapa[anio]!.toList()
      ..sort((a, b) => b.compareTo(a));

    resultado[anio] = mesesOrdenados;
  }

  return resultado;
}


  String _nombreMes(int mes) {
    const meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return (mes < 1 || mes > 12) ? '$mes' : meses[mes];
  }

  // =====================================================
  // APLICAR FILTRO
  // =====================================================
  void _aplicarFiltro({
    required String tipo,
    int? mes,
    int? anio,
  }) {
    final now = DateTime.now();

    setState(() {
      filtroActual = tipo;
      filtroMesCustom = mes;
      filtroAnioCustom = anio;

      if (tipo == 'todas') {
        ventasFiltradas = List<Map<String, dynamic>>.from(ventas);
        return;
      }

      ventasFiltradas = ventas.where((v) {
        final fecha = DateTime.tryParse(v['created_at'] ?? "");
        if (fecha == null) return false;

        switch (tipo) {
          case 'hoy':
            return fecha.year == now.year &&
                fecha.month == now.month &&
                fecha.day == now.day;

          case 'ayer':
            final ayer = now.subtract(const Duration(days: 1));
            return fecha.year == ayer.year &&
                fecha.month == ayer.month &&
                fecha.day == ayer.day;

          case 'mes_actual':
            return fecha.year == now.year && fecha.month == now.month;

          case 'mes_anterior':
            final prev = DateTime(now.year, now.month - 1, 1);
            return fecha.year == prev.year && fecha.month == prev.month;

          case 'mes_custom':
            return fecha.year == anio && fecha.month == mes;

          default:
            return true;
        }
      }).toList();
    });
  }

  // =====================================================
  // BOTTOM SHEET FILTROS — AHORA CON AGRUPACIÓN POR AÑOS
  // =====================================================
  void _mostrarFiltros() {
    final mesesAgrupados = _agruparMesesPorAnio();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Filtrar ventas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C3A50),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Color(0xFF8C3A50)),
                          title: const Text("Hoy"),
                          onTap: () {
                            Navigator.pop(context);
                            _aplicarFiltro(tipo: 'hoy');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.watch_later_outlined,
                              color: Color(0xFF8C3A50)),
                          title: const Text("Ayer"),
                          onTap: () {
                            Navigator.pop(context);
                            _aplicarFiltro(tipo: 'ayer');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_month,
                              color: Color(0xFF8C3A50)),
                          title: const Text("Mes actual"),
                          onTap: () {
                            Navigator.pop(context);
                            _aplicarFiltro(tipo: 'mes_actual');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_view_month,
                              color: Color(0xFF8C3A50)),
                          title: const Text("Mes anterior"),
                          onTap: () {
                            Navigator.pop(context);
                            _aplicarFiltro(tipo: 'mes_anterior');
                          },
                        ),

                        const Divider(),

                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 6),
                          child: Text(
                            "Otros meses",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A4740),
                            ),
                          ),
                        ),

                        // ⭐ AGRUPADO POR AÑOS
                        for (final entry in mesesAgrupados.entries)
                          ExpansionTile(
                            title: Text(
                              entry.key.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8C3A50),
                              ),
                            ),
                            children: [
                              for (final mes in entry.value)
                                ListTile(
                                  leading: const Icon(Icons.date_range,
                                      color: Color(0xFF8C3A50)),
                                  title: Text(
                                      "${_nombreMes(mes)} ${entry.key}"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _aplicarFiltro(
                                      tipo: 'mes_custom',
                                      mes: mes,
                                      anio: entry.key,
                                    );
                                  },
                                )
                            ],
                          ),

                        const Divider(),

                        ListTile(
                          leading:
                              const Icon(Icons.filter_alt_off, color: Colors.red),
                          title: const Text("Quitar filtros"),
                          onTap: () {
                            Navigator.pop(context);
                            _aplicarFiltro(tipo: 'todas');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // UI PRINCIPAL
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE8D8),
        elevation: 0,
        title: const Text(
          "Ventas",
          style: TextStyle(color: Color(0xFF5A4740)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A4740)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8C3A50),
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistroVentaPage()),
          );
          if (resultado == true) _cargarVentas();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // =====================================================
                // DASHBOARD
                // =====================================================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _tarjetaDashboard("Hoy", totalHoy, Colors.pink.shade100),
                      _tarjetaDashboard(
                          "Semana", totalSemana, Colors.blue.shade100),
                      _tarjetaDashboard(
                          "Mes", totalMes, Colors.green.shade100),
                    ],
                  ),
                ),

                const Divider(),

                // =====================================================
                // LISTA
                // =====================================================
                Expanded(
                  child: ventasFiltradas.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay ventas en este periodo",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF5A4740),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ventasFiltradas.length,
                          itemBuilder: (_, i) {
                            final v = ventasFiltradas[i];

                            final cliente =
                                (v['cliente_nombre'] ?? '').toString().trim();
                            final total = v['total_venta'] ?? 0;
                            final fecha =
                                _formatearFecha(v['created_at']?.toString());

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: _cardBox(),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF8C3A50),
                                  size: 34,
                                ),
                                title: Text(
                                  cliente.isEmpty
                                      ? "Cliente sin nombre"
                                      : cliente,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5A4740),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total: Bs $total",
                                      style: const TextStyle(
                                          color: Color(0xFF8C3A50)),
                                    ),
                                    Text(
                                      fecha,
                                      style: const TextStyle(
                                        color: Color(0xFF5A4740),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetalleVentaPage(venta: v),
                                    ),
                                  );
                                  if (resultado == true) _cargarVentas();
                                },
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
