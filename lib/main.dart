import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'pages/registro_venta_page.dart';
import 'pages/menu_principal.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MenuPrincipal(), // <--- CAMBIADO
  ));
}

class SyncDemoPage extends StatefulWidget {
  const SyncDemoPage({super.key});
  @override
  State<SyncDemoPage> createState() => _SyncDemoPageState();
}

class _SyncDemoPageState extends State<SyncDemoPage> {
  final db = DatabaseHelper();
  final sync = SyncService();
  final conn = ConnectivityService();

  List<Map<String, dynamic>> pendientes = [];
  bool conectado = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
    _escucharConexion();
  }

  Future<void> _cargarPendientes() async {
    final p = await db.getVentasPendientes();
    setState(() => pendientes = p);
  }

  void _escucharConexion() async {
    conectado = await conn.hasConnection();
    setState(() {});
    conn.connectionStream.listen((has) async {
      setState(() => conectado = has);
      if (has) {
        await _sincronizar(); // Auto-sync al reconectar
      }
    });
  }


  Future<void> _sincronizar() async {
    if (cargando) return;
    setState(() => cargando = true);
    final report = await sync.syncVentas();
    await _cargarPendientes();
    setState(() => cargando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sync completado → Pendientes: ${report.totalPendientes}, Éxitosas: ${report.sincronizadas}, Fallidas: ${report.falladas}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = conectado
        ? const Chip(label: Text('Conectado'), backgroundColor: Colors.greenAccent)
        : const Chip(label: Text('Sin conexión'), backgroundColor: Colors.redAccent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync OFFLINE → ONLINE'),
        actions: [Padding(padding: const EdgeInsets.all(8), child: badge)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroVentaPage()),
    ).then((_) => _cargarPendientes()); // recarga la lista al volver
  },
  icon: const Icon(Icons.add),
  label: const Text('Nueva venta'),
),

                ElevatedButton.icon(
                  onPressed: _sincronizar,
                  icon: const Icon(Icons.sync),
                  label: Text(cargando ? 'Sincronizando...' : 'Sincronizar ahora'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pendientes: ${pendientes.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),
            Expanded(
              child: pendientes.isEmpty
                  ? const Center(
                      child: Text('No hay ventas pendientes.'),
                    )
                  : ListView.separated(
                      itemCount: pendientes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final v = pendientes[i];
                        return ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text(v['cliente_nombre'] ?? '—'),
                          subtitle: Text('Total: Bs ${v['total_venta']}'),
                          trailing: const Icon(Icons.cloud_off),
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
