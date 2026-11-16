// ==========================================
// IMPORTACIONES DE PAQUETES
// ==========================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../modelos/movimiento_modelo.dart';
import '../modelos/deuda_modelo.dart';
import '../modelos/meta_modelo.dart';

// ==========================================
// SERVICIO SINGLETON: GESTOR DE BASE DE DATOS SQLITE
// ==========================================
class BaseDatosServicio {
  static final BaseDatosServicio instancia = BaseDatosServicio._iniciar();
  static Database? _baseDatos;

  // Ruta opcional para pruebas en memoria (inMemoryDatabasePath)
  static String? rutaPersonalizada;

  BaseDatosServicio._iniciar();

  // Reiniciar la conexión para pruebas
  static Future<void> reiniciarParaPruebas() async {
    if (_baseDatos != null) {
      await _baseDatos!.close();
      _baseDatos = null;
    }
  }

  // Getter asíncrono para obtener la instancia de SQLite
  Future<Database> get database async {
    if (_baseDatos != null) return _baseDatos!;
    _baseDatos = await _inicializarBaseDatos();
    return _baseDatos!;
  }

  // Inicialización de la base de datos según la plataforma
  Future<Database> _inicializarBaseDatos() async {
    // Si corre en Windows, Linux o macOS, inicializamos el factory FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String rutaCompleta;
    if (rutaPersonalizada != null) {
      rutaCompleta = rutaPersonalizada!;
    } else {
      final String rutaDirectorio = await getDatabasesPath();
      rutaCompleta = p.join(rutaDirectorio, 'finanzas_locales.db');
    }

    return await openDatabase(
      rutaCompleta,
      version: 1,
      onCreate: _crearTablas,
    );
  }

  // Creación del esquema relacional
  Future<void> _crearTablas(Database db, int version) async {
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
  }

  // Vaciar completamente todas las tablas de la base de datos
  Future<void> vaciarBaseDatos() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('partidas_deuda');
      await txn.delete('movimientos');
      await txn.delete('deudas');
      await txn.delete('metas');
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
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.delete(
      'movimientos',
      where: 'id = ?',
      whereArgs: [id],
    );
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

      final partidas = partidasMaps.map((p) => PartidaDeudaModelo.fromMap(p)).toList();
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
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final partida in deuda.historialPartidas) {
        await txn.insert(
          'partidas_deuda',
          partida.toMap(idDeuda: deuda.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
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
      await txn.delete('partidas_deuda', where: 'idDeuda = ?', whereArgs: [deuda.id]);
      for (final partida in deuda.historialPartidas) {
        await txn.insert(
          'partidas_deuda',
          partida.toMap(idDeuda: deuda.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
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
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.delete(
      'metas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
