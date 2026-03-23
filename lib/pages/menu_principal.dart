import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'fardos_page.dart';
import 'ventas_page.dart';
import 'prendas_page.dart';
import 'estadisticas_page.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  // 🎨 Paleta basada en el logo Pura Pinta
  static const Color fondoCrema = Color(0xFFF4E6D3);
  static const Color vino = Color(0xFFA34835);
  static const Color cuero = Color(0xFF6A3F2A);
  static const Color jeans = Color(0xFF3E5A70);
  static const Color grafico = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "PURA PINTA",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: grafico,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: [
                  _glassButton(
                    titulo: "Ventas",
                    tint: vino,
                    icono: Icons.point_of_sale,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VentasPage()),
                      );
                    },
                  ),
                  _glassButton(
                    titulo: "Fardos",
                    tint: cuero,
                    icono: Icons.inventory_2,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FardosPage()),
                      );
                    },
                  ),
                  _glassButton(
                    titulo: "Prendas",
                    tint: jeans,
                    icono: Icons.checkroom,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrendasPage()),
                      );
                    },
                  ),
                  _glassButton(
                    titulo: "Estado",
                    tint: grafico,
                    icono: Icons.bar_chart,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EstadisticasPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botón limpiar DB
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vino.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () async {
                await DatabaseHelper().clearDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Base de datos limpiada correctamente")),
                );
              },
              child: const Text(
                "Limpiar DB (solo pruebas)",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ Tarjeta estilo glass + tinte
  Widget _glassButton({
    required String titulo,
    required Color tint,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: tint.withOpacity(0.18), // tinte suave
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: tint.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 48, color: tint.withOpacity(0.9)),
                  const SizedBox(height: 10),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tint.withOpacity(0.95),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
