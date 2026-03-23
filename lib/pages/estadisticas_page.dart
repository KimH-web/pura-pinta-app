import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final db = DatabaseHelper();

  bool cargando = true;
  String periodoSeleccionado = 'dia'; // 'dia' | 'semana' | 'mes'

  // Totales encabezado
  double totalHoy = 0;
  double totalSemana = 0;
  double totalMes = 0;

  // Para gráfico vertical tipo Yango (todas las ventas históricas)
  final Map<DateTime, double> _mapDia = {};     // clave = DateTime(yyyy,MM,dd)
  final Map<DateTime, double> _mapSemana = {};  // clave = lunes de esa semana
  final Map<DateTime, double> _mapMes = {};     // clave = DateTime(yyyy,MM,1)

  // Para "Ventas por día del mes" (solo mes actual)
  Map<int, double> ventasPorDiaMesActual = {};  // dia -> monto

  // Top prendas
  Map<String, double> prendasTop = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // =====================================================
  // CARGA Y CÁLCULO DE ESTADÍSTICAS
  // =====================================================
  Future<void> _cargarDatos() async {
    try {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      final dataVentas = await db.getAllVentas();

      _mapDia.clear();
      _mapSemana.clear();
      _mapMes.clear();
      ventasPorDiaMesActual = {};

      for (final v in dataVentas) {
        final fechaIso = v['created_at']?.toString() ?? '';
        final fechaOriginal = DateTime.tryParse(fechaIso);
        if (fechaOriginal == null) continue;

        final fecha = DateTime(
          fechaOriginal.year,
          fechaOriginal.month,
          fechaOriginal.day,
        );

        final total = (v['total_venta'] as num?)?.toDouble() ?? 0.0;

        // ----------------- Día -----------------
        _mapDia[fecha] = (_mapDia[fecha] ?? 0) + total;

        // ---------------- Semana (lunes–domingo) ----------------
        final inicioSemana =
            fecha.subtract(Duration(days: fecha.weekday - 1)); // lunes
        _mapSemana[inicioSemana] =
            (_mapSemana[inicioSemana] ?? 0) + total;

        // ---------------- Mes ----------------
        final inicioMes = DateTime(fecha.year, fecha.month, 1);
        _mapMes[inicioMes] = (_mapMes[inicioMes] ?? 0) + total;

        // ---------------- Ventas por día del MES ACTUAL ----------------
        if (fecha.year == ahora.year && fecha.month == ahora.month) {
          final dia = fecha.day;
          ventasPorDiaMesActual[dia] =
              (ventasPorDiaMesActual[dia] ?? 0) + total;
        }
      }

      // Totales para encabezado
      final hoyKey = hoy;
      final inicioSemanaHoy =
          hoyKey.subtract(Duration(days: hoyKey.weekday - 1));
      final inicioMesHoy = DateTime(hoyKey.year, hoyKey.month, 1);

      totalHoy = _mapDia[hoyKey] ?? 0;
      totalSemana = _mapSemana[inicioSemanaHoy] ?? 0;
      totalMes = _mapMes[inicioMesHoy] ?? 0;

      // Top prendas históricas
      final dbConn = await db.database;
      final filasTop = await dbConn.rawQuery('''
        SELECT p.nombre AS prenda_nombre,
               SUM(dv.cantidad) AS total_cantidad
        FROM detalle_ventas dv
        LEFT JOIN prendas p ON p.id = dv.prenda_id
        GROUP BY dv.prenda_id, p.nombre
        ORDER BY total_cantidad DESC
        LIMIT 5
      ''');

      prendasTop = {
        for (final fila in filasTop)
          (fila['prenda_nombre'] as String? ?? 'Sin nombre'):
              (fila['total_cantidad'] as num?)?.toDouble() ?? 0.0
      };

      if (!mounted) return;
      setState(() {
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  // =====================================================
  // HELPERS DE PERIODO
  // =====================================================
  double _montoPeriodoSeleccionado() {
    switch (periodoSeleccionado) {
      case 'semana':
        return totalSemana;
      case 'mes':
        return totalMes;
      case 'dia':
      default:
        return totalHoy;
    }
  }

  String _mensajeNoDataPeriodo() {
    switch (periodoSeleccionado) {
      case 'semana':
        return 'No hay información de ganancias para esta semana';
      case 'mes':
        return 'No hay información de ganancias para este mes';
      case 'dia':
      default:
        return 'No hay información de ganancias para este día';
    }
  }

  String _mesCorto(int mes) {
    const nombres = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    if (mes < 1 || mes > 12) return '';
    return nombres[mes - 1];
  }

  String _formatearMonto(double monto) {
    // 70.0 -> "70.00"
    return monto.toStringAsFixed(2);
  }

  // =====================================================
  // SEGMENTO DÍA / SEMANA / MES
  // =====================================================
  Widget _segmentoPeriodo(String texto, String valor) {
    final seleccionado = periodoSeleccionado == valor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!seleccionado) {
            setState(() {
              periodoSeleccionado = valor;
            });
          }
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: seleccionado ? Colors.white : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: seleccionado ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // GRÁFICO PRINCIPAL VERTICAL TIPO YANGO
  // =====================================================
  Widget _graficoPrincipalVertical() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final List<_BarData> barras = [];

    if (periodoSeleccionado == 'dia') {
      // Últimos 180 días (≈ 6 meses) desde hoy hacia atrás
      const int rangoDias = 180;
      for (int i = rangoDias - 1; i >= 0; i--) {
        final fecha = hoy.subtract(Duration(days: i));
        final monto = _mapDia[fecha] ?? 0.0;
        barras.add(
          _BarData(
            monto: monto,
            label1: fecha.day.toString(),
            label2: _mesCorto(fecha.month),
          ),
        );
      }
    } else if (periodoSeleccionado == 'semana') {
      // Últimas 24 semanas
      const int rangoSemanas = 24;
      final inicioSemanaHoy =
          hoy.subtract(Duration(days: hoy.weekday - 1)); // lunes actual

      for (int i = rangoSemanas - 1; i >= 0; i--) {
        final inicio = inicioSemanaHoy.subtract(Duration(days: 7 * i));
        final fin = inicio.add(const Duration(days: 6));
        final monto = _mapSemana[inicio] ?? 0.0;

        final label1 = '${inicio.day}-${fin.day}';
        final label2 = _mesCorto(inicio.month);

        barras.add(
          _BarData(
            monto: monto,
            label1: label1,
            label2: label2,
          ),
        );
      }
    } else {
      // periodoSeleccionado == 'mes'
      // Últimos 12 meses
      const int rangoMeses = 12;
      final mesActual = DateTime(hoy.year, hoy.month, 1);

      for (int i = rangoMeses - 1; i >= 0; i--) {
        final fechaMes = DateTime(mesActual.year, mesActual.month - i, 1);
        final monto = _mapMes[fechaMes] ?? 0.0;

        barras.add(
          _BarData(
            monto: monto,
            label1: _mesCorto(fechaMes.month),
            label2: fechaMes.year.toString(),
          ),
        );
      }
    }

    if (barras.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxMonto = 0;
    for (final b in barras) {
      if (b.monto > maxMonto) maxMonto = b.monto;
    }
    if (maxMonto <= 0) {
      maxMonto = 1; // para evitar división por cero
    }

    const double alturaMin = 24;
    const double alturaExtra = 96; // altura total máx ≈ 120

    return SizedBox(
      height: 230,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: barras.map((b) {
            final factor = (b.monto / maxMonto).clamp(0.0, 1.0);
            final barHeight = alturaMin + factor * alturaExtra;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (b.monto > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _formatearMonto(b.monto),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Container(
                    width: 44,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C8DFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.label1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    b.label2,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // =====================================================
  // GRÁFICO HORIZONTAL: VENTAS POR DÍA DEL MES ACTUAL
  // =====================================================
  Widget _graficoVentasPorDiaMesActual() {
    if (ventasPorDiaMesActual.isEmpty) {
      return const Text(
        'No hay datos de ventas este mes',
        style: TextStyle(color: Colors.white70),
      );
    }

    final maxValor = ventasPorDiaMesActual.values.fold<double>(
      0,
      (a, b) => a > b ? a : b,
    );
    if (maxValor <= 0) {
      return const Text(
        'No hay montos positivos de ventas',
        style: TextStyle(color: Colors.white70),
      );
    }

    final entradasOrdenadas = ventasPorDiaMesActual.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entradasOrdenadas.map((entry) {
        final dia = entry.key;
        final monto = entry.value;
        final porcentaje = (monto / maxValor).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  dia.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4C8DFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(
                  'Bs ${monto.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================
  // GRÁFICO: TOP 5 PRENDAS
  // =====================================================
  Widget _graficoTopPrendas() {
    if (prendasTop.isEmpty) {
      return const Text(
        'No hay ventas registradas',
        style: TextStyle(color: Colors.white70),
      );
    }

    final maxValor = prendasTop.values.fold<double>(
      0,
      (a, b) => a > b ? a : b,
    );
    if (maxValor <= 0) {
      return const Text(
        'No hay cantidades positivas',
        style: TextStyle(color: Colors.white70),
      );
    }

    final entradasOrdenadas = prendasTop.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entradasOrdenadas.map((entry) {
        final nombre = entry.key;
        final cantidad = entry.value;
        final porcentaje = (cantidad / maxValor).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 7,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: porcentaje,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  cantidad.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final montoPeriodo = _montoPeriodoSeleccionado();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Estadísticas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Selector Día / Semana / Mes
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      _segmentoPeriodo('Día', 'dia'),
                      const SizedBox(width: 4),
                      _segmentoPeriodo('Semana', 'semana'),
                      const SizedBox(width: 4),
                      _segmentoPeriodo('Mes', 'mes'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Monto principal
                Text(
                  'Bs ${montoPeriodo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (montoPeriodo <= 0)
                  Text(
                    _mensajeNoDataPeriodo(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                const SizedBox(height: 24),

                // Gráfico vertical tipo Yango
                _graficoPrincipalVertical(),

                const SizedBox(height: 32),

                // Ventas por día del mes
                const Text(
                  'Ventas por día del mes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _graficoVentasPorDiaMesActual(),

                const SizedBox(height: 28),

                // Top prendas
                const Text(
                  'Top 5 prendas más vendidas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _graficoTopPrendas(),
              ],
            ),
    );
  }
}

// =========================================================
// MODELO INTERNO PARA BARRAS DEL GRÁFICO PRINCIPAL
// =========================================================
class _BarData {
  final double monto;
  final String label1;
  final String label2;

  _BarData({
    required this.monto,
    required this.label1,
    required this.label2,
  });
}
