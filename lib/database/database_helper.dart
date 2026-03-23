import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// =============================================================
///  DATABASE HELPER – PURA PINTA APP
/// =============================================================
class DatabaseHelper {
  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pura_pinta.db');

    return await openDatabase(
      path,
      version: 4, // ⬅️ Subimos a versión 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTablePrendas(db);
    await _createTableFardos(db);
    await _createTableFardoDetalles(db);
    await _createTableVentas(db);
    await _createTableDetalleVentas(db);
  }

  Future<void> _createTablePrendas(Database db) async {
    await db.execute('''
      CREATE TABLE prendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        stock_total INTEGER DEFAULT 0,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createTableFardos(Database db) async {
    await db.execute('''
      CREATE TABLE fardos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT,
        costo_total REAL,
        fecha_compra TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createTableFardoDetalles(Database db) async {
    await db.execute('''
      CREATE TABLE fardo_detalles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fardo_id INTEGER,
        prenda_id INTEGER,
        cantidad_inicial INTEGER,
        precio_referencial REAL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (fardo_id) REFERENCES fardos(id),
        FOREIGN KEY (prenda_id) REFERENCES prendas(id)
      )
    ''');
  }

  Future<void> _createTableVentas(Database db) async {
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_nombre TEXT,
        cliente_celular TEXT,
        total_venta REAL,
        sincronizado INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createTableDetalleVentas(Database db) async {
    await db.execute('''
      CREATE TABLE detalle_ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER,
        prenda_id INTEGER,
        cantidad INTEGER,
        precio_unitario REAL,
        subtotal REAL,
        sincronizado INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (prenda_id) REFERENCES prendas(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ajuste que ya tenías para fardo_detalles
    //if (oldVersion < 3) {
    //  await db.execute("DROP TABLE IF EXISTS fardo_detalles");
    //  await _createTableFardoDetalles(db);
    //}

    // Nuevo: agregar timestamps a ventas y detalle_ventas
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE ventas ADD COLUMN created_at TEXT");
      await db.execute(
          "ALTER TABLE ventas ADD COLUMN updated_at TEXT");

      await db.execute(
          "ALTER TABLE detalle_ventas ADD COLUMN created_at TEXT");
      await db.execute(
          "ALTER TABLE detalle_ventas ADD COLUMN updated_at TEXT");
    }
  }

  // =============================================================
  //  FARDOS
  // =============================================================
  Future<int> insertFardo(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("fardos", data);
  }

  Future<List<Map<String, dynamic>>> getFardos() async {
    final db = await database;
    return await db.query("fardos", orderBy: "id DESC");
  }

  Future<int> updateFardo(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update("fardos", data, where: "id = ?", whereArgs: [id]);
  }

  /// Obtener fardo por id
  Future<Map<String, dynamic>?> getFardoById(int id) async {
    final db = await database;
    final r = await db.query(
      "fardos",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    return r.isNotEmpty ? r.first : null;
  }

  // =============================================================
  //  DETALLES DE FARDOS
  // =============================================================
  Future<int> insertDetalleFardo(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("fardo_detalles", data);
  }

  Future<List<Map<String, dynamic>>> getDetallesFardo(int fardoId) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT fd.id,
             fd.fardo_id,
             fd.prenda_id,
             fd.cantidad_inicial,
             fd.precio_referencial,
             p.nombre AS prenda_nombre
      FROM fardo_detalles fd
      LEFT JOIN prendas p ON p.id = fd.prenda_id
      WHERE fd.fardo_id = ?
    ''', [fardoId]);
  }

  Future<int> updateDetalleFardo(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      "fardo_detalles",
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> recalcularPreciosReferenciales(int fardoId) async {
    final db = await database;

    final detalles = await db.rawQuery('''
      SELECT id, cantidad_inicial
      FROM fardo_detalles
      WHERE fardo_id = ?
    ''', [fardoId]);

    if (detalles.isEmpty) return;

    final totalCant = detalles.fold<int>(
      0,
      (sum, item) => sum + (item['cantidad_inicial'] as int),
    );

    final fardo = await db.query(
      "fardos",
      where: "id = ?",
      whereArgs: [fardoId],
      limit: 1,
    );

    if (fardo.isEmpty) return;

    final costoTotal = fardo.first['costo_total'] as num;
    final precioUnit = costoTotal / totalCant;

    for (var item in detalles) {
      await db.update(
        "fardo_detalles",
        {
          "precio_referencial":
              double.parse(precioUnit.toStringAsFixed(1)),
          "updated_at": DateTime.now().toString(),
        },
        where: "id = ?",
        whereArgs: [item['id']],
      );
    }
  }

  // =============================================================
  //  PRENDAS
  // =============================================================
  Future<int> insertPrenda(Map<String, dynamic> prenda) async {
    final db = await database;
    return await db.insert("prendas", prenda);
  }

  Future<List<Map<String, dynamic>>> getPrendas() async {
    final db = await database;
    return await db.query("prendas");
  }

  Future<Map<String, dynamic>?> getPrendaById(int id) async {
    final db = await database;
    final r = await db.query(
      "prendas",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    return r.isNotEmpty ? r.first : null;
  }

  Future<Map<String, dynamic>?> getPrendaByName(String nombre) async {
    final db = await database;
    final r = await db.query(
      "prendas",
      where: "nombre = ?",
      whereArgs: [nombre],
      limit: 1,
    );
    return r.isNotEmpty ? r.first : null;
  }

  Future<int> getOrCreatePrenda(String nombre) async {
    final existente = await getPrendaByName(nombre);
    if (existente != null) return existente["id"] as int;

    return await insertPrenda({
      "nombre": nombre,
      "stock_total": 0,
      "sincronizado": 0,
    });
  }

  Future<void> sumarStock(int prendaId, int cantidad) async {
    final db = await database;

    final prenda = await getPrendaById(prendaId);
    if (prenda == null) return;

    final nuevo = (prenda['stock_total'] ?? 0) + cantidad;

    await db.update(
      "prendas",
      {"stock_total": nuevo},
      where: "id = ?",
      whereArgs: [prendaId],
    );
  }

  Future<void> restarStock(int prendaId, int cantidad) async {
    final db = await database;

    final prenda = await getPrendaById(prendaId);
    if (prenda == null) return;

    final actual = (prenda['stock_total'] ?? 0) as int;
    final nuevo = actual - cantidad;

    await db.update(
      "prendas",
      {"stock_total": nuevo},
      where: "id = ?",
      whereArgs: [prendaId],
    );
  }

  // =============================================================
  //  VENTAS
  // =============================================================
  Future<int> insertVenta(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("ventas", data);
  }

  Future<int> insertDetalleVenta(Map<String, dynamic> data) async {
    final db = await database;
    data['sincronizado'] = data['sincronizado'] ?? 0;
    return await db.insert("detalle_ventas", data);
  }

  Future<List<Map<String, dynamic>>> getAllVentas() async {
    final db = await database;
    return await db.query("ventas", orderBy: "id DESC");
  }

  Future<List<Map<String, dynamic>>> getVentasPendientes() async {
    final db = await database;
    return await db.query("ventas", where: "sincronizado = 0");
  }

  Future<int> marcarVentaSincronizada(int id) async {
    final db = await database;
    return await db.update(
      "ventas",
      {"sincronizado": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  /// 🔍 Detalles de una venta (útil si luego quieres una pantalla DetalleVentaPage)
  Future<List<Map<String, dynamic>>> getDetallesVenta(int ventaId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT dv.id, dv.venta_id, dv.prenda_id, dv.cantidad, dv.precio_unitario, dv.subtotal,
             p.nombre AS prenda_nombre
      FROM detalle_ventas dv
      LEFT JOIN prendas p ON p.id = dv.prenda_id
      WHERE dv.venta_id = ?
    ''', [ventaId]);
  }

  Future<void> eliminarVenta(int ventaId) async {
  final db = await database;

  // 1. Obtener todos los detalles de esa venta
  final detalles = await db.query(
    'detalle_ventas',
    where: 'venta_id = ?',
    whereArgs: [ventaId],
  );

  // 2. Revertir stock
  for (var d in detalles) {
    final prendaId = d['prenda_id'] as int;
    final cantidadVendida = d['cantidad'] as int;
    await sumarStock(prendaId, cantidadVendida);
  }

  // 3. Eliminar los detalles
  await db.delete(
    'detalle_ventas',
    where: 'venta_id = ?',
    whereArgs: [ventaId],
  );

  // 4. Eliminar la venta
  await db.delete(
    'ventas',
    where: 'id = ?',
    whereArgs: [ventaId],
  );
}

  // =============================================================
  //  UTILIDADES
  // =============================================================
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete("fardo_detalles");
    await db.delete("fardos");
    await db.delete("detalle_ventas");
    await db.delete("ventas");
    await db.delete("prendas");
  }
}
