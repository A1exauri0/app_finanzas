// ==========================================
// IMPORTACIONES DE PAQUETES
// ==========================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../modelos/movimiento_modelo.dart';
import '../modelos/deuda_modelo.dart';
import '../modelos/meta_modelo.dart';
import '../modelos/gasto_fijo_modelo.dart';

// ==========================================
// SERVICIO SINGLETON: GESTOR DE BASE DE DATOS SQLITE
// ==========================================
class BaseDatosServicio {
  static final BaseDatosServicio instancia = BaseDatosServicio._iniciar();
  static sqflite.Database? _baseDatos;

  // Ruta opcional para pruebas en memoria (inMemoryDatabasePath)
  static String? rutaPersonalizada;

  BaseDatosServicio._iniciar();

  // Método público para asegurar que la fábrica esté configurada antes de cualquier consulta
  static void inicializarFabricaSQLite() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqflite_ffi.sqfliteFfiInit();
      sqflite.databaseFactory = sqflite_ffi.databaseFactoryFfi;
    } else {
      sqflite.databaseFactory = sqflite.databaseFactorySqflitePlugin;
    }
  }

  // Obtener la fábrica correcta según la plataforma activa (Android, iOS o Desktop FFI)
  static sqflite.DatabaseFactory get _obtenerFabricaActiva {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqflite_ffi.sqfliteFfiInit();
      return sqflite_ffi.databaseFactoryFfi;
    }
    return sqflite.databaseFactorySqflitePlugin;
  }

  // Reiniciar la conexión para pruebas
  static Future<void> reiniciarParaPruebas() async {
    if (_baseDatos != null) {
      await _baseDatos!.close();
      _baseDatos = null;
    }
  }

  // Getter asíncrono para obtener la instancia de SQLite
  Future<sqflite.Database> get database async {
    if (_baseDatos != null) return _baseDatos!;
    _baseDatos = await _inicializarBaseDatos();
    return _baseDatos!;
  }

  // Inicialización de la base de datos según la plataforma
  Future<sqflite.Database> _inicializarBaseDatos() async {
    inicializarFabricaSQLite();
    final sqflite.DatabaseFactory fabrica = _obtenerFabricaActiva;

    final String rutaCompleta;
    if (rutaPersonalizada != null) {
      rutaCompleta = rutaPersonalizada!;
    } else {
      final String rutaDirectorio = await fabrica.getDatabasesPath();
      rutaCompleta = p.join(rutaDirectorio, 'finanzas_locales.db');
    }

    final db = await fabrica.openDatabase(
      rutaCompleta,
      options: sqflite.OpenDatabaseOptions(version: 1, onCreate: _crearTablas),
    );

    // Aseguramos que la tabla de configuraciones exista para preferencias
    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    // Aseguramos que la tabla de gastos fijos y suscripciones exista
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos_fijos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        diaPago INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        iconoCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        pagarConTarjeta INTEGER NOT NULL DEFAULT 0,
        idTarjeta TEXT,
        nombreTarjeta TEXT,
        ultimoMesPagado TEXT
      )
    ''');

    return db;
  }

  // Creación del esquema relacional
  Future<void> _crearTablas(sqflite.Database db, int version) async {
    // 0. Tabla de Configuraciones y Preferencias
    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuraciones (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    // 1. Tabla de Movimientos
    await db.execute('''
      CREATE TABLE movimientos (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        tipo TEXT NOT NULL,
        iconoCodePoint INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        idDeudaAsociada TEXT,
        nombreDeudorAsociado TEXT,
        pagadoConTarjeta INTEGER NOT NULL DEFAULT 0,
        idTarjetaUtilizada TEXT,
        nombreTarjetaUtilizada TEXT
      )
    ''');

    // 2. Tabla de Deudas y Tarjetas
    await db.execute('''
      CREATE TABLE deudas (
        id TEXT PRIMARY KEY,
        tituloOEntidad TEXT NOT NULL,
        tipoDeuda TEXT NOT NULL,
        montoTotal REAL NOT NULL,
        limiteAjustado REAL,
        montoPendiente REAL NOT NULL,
        fechaLimitePago TEXT,
        diaCorte INTEGER,
        colorTarjetaValue INTEGER,
        notas TEXT
      )
    ''');

    // 3. Tabla de Partidas e Historial de Deudas
    await db.execute('''
      CREATE TABLE partidas_deuda (
        id TEXT PRIMARY KEY,
        idDeuda TEXT NOT NULL,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        esAbono INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (idDeuda) REFERENCES deudas (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla de Metas y Objetivos de Ahorro
    await db.execute('''
      CREATE TABLE metas (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        montoObjetivo REAL NOT NULL,
        montoAhorrado REAL NOT NULL DEFAULT 0,
        fechaObjetivo TEXT,
        iconoCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        notas TEXT
      )
    ''');

    // 5. Tabla de Gastos Fijos y Suscripciones Recurrentes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos_fijos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        diaPago INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        iconoCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        pagarConTarjeta INTEGER NOT NULL DEFAULT 0,
        idTarjeta TEXT,
        nombreTarjeta TEXT,
        ultimoMesPagado TEXT
      )
    ''');
  }

  // Vaciar completamente todas las tablas de la base de datos
  Future<void> vaciarBaseDatos() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('partidas_deuda');
      await txn.delete('movimientos');
      await txn.delete('deudas');
      await txn.delete('metas');
      await txn.delete('gastos_fijos');
    });
  }

  // ==========================================
  // OPERACIONES CRUD: MOVIMIENTOS
  // ==========================================
  Future<List<MovimientoModelo>> obtenerMovimientos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movimientos',
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => MovimientoModelo.fromMap(m)).toList();
  }

  Future<void> insertarMovimiento(MovimientoModelo movimiento) async {
    final db = await database;
    await db.insert(
      'movimientos',
      movimiento.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizarMovimiento(MovimientoModelo movimiento) async {
    final db = await database;
    await db.update(
      'movimientos',
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

  Future<void> eliminarMovimiento(String id) async {
    final db = await database;
    await db.delete('movimientos', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD: DEUDAS Y TARJETAS
  // ==========================================
  Future<List<DeudaModelo>> obtenerDeudas() async {
    final db = await database;
    final List<Map<String, dynamic>> deudasMaps = await db.query('deudas');

    final List<DeudaModelo> listaDeudas = [];
    for (final map in deudasMaps) {
      final String idDeuda = map['id'] as String;
      final List<Map<String, dynamic>> partidasMaps = await db.query(
        'partidas_deuda',
        where: 'idDeuda = ?',
        whereArgs: [idDeuda],
        orderBy: 'fecha DESC',
      );

      final partidas = partidasMaps
          .map((p) => PartidaDeudaModelo.fromMap(p))
          .toList();
      listaDeudas.add(DeudaModelo.fromMap(map, partidas: partidas));
    }

    return listaDeudas;
  }

  Future<void> insertarDeuda(DeudaModelo deuda) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'deudas',
        deuda.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      for (final partida in deuda.historialPartidas) {
        await txn.insert(
          'partidas_deuda',
          partida.toMap(idDeuda: deuda.id),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> actualizarDeuda(DeudaModelo deuda) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'deudas',
        deuda.toMap(),
        where: 'id = ?',
        whereArgs: [deuda.id],
      );

      // Reemplazamos partidas del historial para mantener sincronía
      await txn.delete(
        'partidas_deuda',
        where: 'idDeuda = ?',
        whereArgs: [deuda.id],
      );
      for (final partida in deuda.historialPartidas) {
        await txn.insert(
          'partidas_deuda',
          partida.toMap(idDeuda: deuda.id),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> eliminarDeuda(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('partidas_deuda', where: 'idDeuda = ?', whereArgs: [id]);
      await txn.delete('deudas', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ==========================================
  // OPERACIONES CRUD: METAS DE AHORRO
  // ==========================================
  Future<List<MetaModelo>> obtenerMetas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('metas');
    return maps.map((m) => MetaModelo.fromMap(m)).toList();
  }

  Future<void> insertarMeta(MetaModelo meta) async {
    final db = await database;
    await db.insert(
      'metas',
      meta.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizarMeta(MetaModelo meta) async {
    final db = await database;
    await db.update(
      'metas',
      meta.toMap(),
      where: 'id = ?',
      whereArgs: [meta.id],
    );
  }

  Future<void> eliminarMeta(String id) async {
    final db = await database;
    await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD: GASTOS FIJOS Y SUSCRIPCIONES RECURRENTES
  // ==========================================
  Future<List<GastoFijoModelo>> obtenerGastosFijos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos_fijos',
      orderBy: 'diaPago ASC',
    );
    return maps.map((m) => GastoFijoModelo.fromMap(m)).toList();
  }

  Future<void> insertarGastoFijo(GastoFijoModelo gastoFijo) async {
    final db = await database;
    await db.insert(
      'gastos_fijos',
      gastoFijo.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizarGastoFijo(GastoFijoModelo gastoFijo) async {
    final db = await database;
    await db.update(
      'gastos_fijos',
      gastoFijo.toMap(),
      where: 'id = ?',
      whereArgs: [gastoFijo.id],
    );
  }

  Future<void> eliminarGastoFijo(String id) async {
    final db = await database;
    await db.delete('gastos_fijos', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES: CONFIGURACIONES GENERALES
  // ==========================================
  Future<void> guardarConfiguracion(String clave, String valor) async {
    final db = await database;
    await db.insert(
      'configuraciones',
      {'clave': clave, 'valor': valor},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<String?> obtenerConfiguracion(String clave) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'configuraciones',
      where: 'clave = ?',
      whereArgs: [clave],
    );
    if (res.isNotEmpty) {
      return res.first['valor'] as String?;
    }
    return null;
  }
}
