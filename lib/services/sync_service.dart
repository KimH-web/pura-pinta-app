import 'dart:convert';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import 'connectivity_service.dart';

class SyncReport {
  final int totalPendientes;
  final int sincronizadas;
  final int falladas;

  SyncReport({required this.totalPendientes, required this.sincronizadas, required this.falladas});
}

class SyncService {
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _conn = ConnectivityService();

  // Cambia esta URL cuando tengas tu API Laravel en la nube
  final Uri ventasEndpoint = Uri.parse('https://httpbin.org/status/201'); 
  // ↑ Para probar SIN backend real: siempre responde 201 (creado)

  Future<SyncReport> syncVentas() async {
    final hasNet = await _conn.hasConnection();
    if (!hasNet) return SyncReport(totalPendientes: 0, sincronizadas: 0, falladas: 0);

    final pendientes = await _db.getVentasPendientes();
    int ok = 0, fail = 0;

    for (final v in pendientes) {
      try {
        // Cuando tengas tu API real:
        // final resp = await http.post(ventasEndpointReal, headers: {'Content-Type': 'application/json'}, body: jsonEncode(v));
        final resp = await http.post(ventasEndpoint, headers: {'Content-Type': 'application/json'}, body: jsonEncode(v));

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          await _db.marcarVentaSincronizada(v['id'] as int);
          ok++;
        } else {
          fail++;
        }
      } catch (_) {
        fail++;
      }
    }

    return SyncReport(totalPendientes: pendientes.length, sincronizadas: ok, falladas: fail);
  }
}
