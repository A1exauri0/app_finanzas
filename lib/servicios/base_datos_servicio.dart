// ==========================================
// IMPORTACIONES DE PAQUETES
// ==========================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

    // Carga de datos iniciales demo
    await _insertarDatosIniciales(db);
  }

  // Semilla de datos iniciales (Seed)
  Future<void> _insertarDatosIniciales(Database db) async {
    // 1. Metas iniciales
    final metasIniciales = [
      MetaModelo(
        id: 'meta-1',
        titulo: 'Laptop de Trabajo',
        montoObjetivo: 24000.00,
        montoAhorrado: 15500.00,
        fechaObjetivo: DateTime.now().add(const Duration(days: 90)),
        categoria: 'Tecnología',
        icono: Icons.devices_rounded,
        color: const Color(0xFF1976D2),
      ),
      MetaModelo(
        id: 'meta-2',
        titulo: 'Vacaciones a la Playa',
        montoObjetivo: 14000.00,
        montoAhorrado: 7000.00,
        fechaObjetivo: DateTime.now().add(const Duration(days: 120)),
        categoria: 'Viajes',
        icono: Icons.flight_takeoff_rounded,
        color: const Color(0xFF0097A7),
      ),
      MetaModelo(
        id: 'meta-3',
        titulo: 'Fondo de Emergencia',
        montoObjetivo: 20000.00,
        montoAhorrado: 20000.00,
        categoria: 'Fondo de Emergencia',
        icono: Icons.shield_rounded,
        color: const Color(0xFF2E7D32),
      ),
    ];

    for (final meta in metasIniciales) {
      await db.insert('metas', meta.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. Tarjetas y deudas iniciales
    final deudasIniciales = [
      DeudaModelo(
        id: 'tarjeta-nu',
        tituloOEntidad: 'Nu México',
        tipoDeuda: TipoDeuda.tarjetaCredito,
        montoTotal: 15000.00,
        limiteAjustado: 8000.00,
        montoPendiente: 3200.00,
        diaCorte: 12,
        colorTarjeta: const Color(0xFF820AD1),
        fechaLimitePago: DateTime.now().add(const Duration(days: 10)),
        historialPartidas: [
          PartidaDeudaModelo(
            id: 'nu-1',
            concepto: 'Compra en Amazon',
            monto: 2200.00,
            fecha: DateTime.now().subtract(const Duration(days: 8)),
            esAbono: false,
          ),
          PartidaDeudaModelo(
            id: 'nu-2',
            concepto: 'Cena Restaurante',
            monto: 1000.00,
            fecha: DateTime.now().subtract(const Duration(days: 5)),
            esAbono: false,
          ),
          PartidaDeudaModelo(
            id: 'nu-3',
            concepto: 'Pago mensual para no generar intereses',
            monto: 1500.00,
            fecha: DateTime.now().subtract(const Duration(days: 2)),
            esAbono: true,
          ),
        ],
      ),
      DeudaModelo(
        id: 'tarjeta-didi',
        tituloOEntidad: 'Didi Card',
        tipoDeuda: TipoDeuda.tarjetaCredito,
        montoTotal: 8000.00,
        limiteAjustado: 4000.00,
        montoPendiente: 1450.00,
        diaCorte: 24,
        colorTarjeta: const Color(0xFFFF7700),
        fechaLimitePago: DateTime.now().add(const Duration(days: 15)),
        historialPartidas: [
          PartidaDeudaModelo(
            id: 'didi-1',
            concepto: 'Gasolina',
            monto: 850.00,
            fecha: DateTime.now().subtract(const Duration(days: 4)),
            esAbono: false,
          ),
          PartidaDeudaModelo(
            id: 'didi-2',
            concepto: 'Suscripciones streaming',
            monto: 600.00,
            fecha: DateTime.now().subtract(const Duration(days: 2)),
            esAbono: false,
          ),
        ],
      ),
      DeudaModelo(
        id: 'tarjeta-mp',
        tituloOEntidad: 'Mercado Pago',
        tipoDeuda: TipoDeuda.tarjetaCredito,
        montoTotal: 10000.00,
        montoPendiente: 890.00,
        diaCorte: 5,
        colorTarjeta: const Color(0xFF009EE3),
        fechaLimitePago: DateTime.now().add(const Duration(days: 5)),
        historialPartidas: [
          PartidaDeudaModelo(
            id: 'mp-1',
            concepto: 'Compra Mercado Libre',
            monto: 890.00,
            fecha: DateTime.now().subtract(const Duration(days: 1)),
            esAbono: false,
          ),
        ],
      ),
      DeudaModelo(
        id: 'deuda-1',
        tituloOEntidad: 'Juan Pérez',
        tipoDeuda: TipoDeuda.meDeben,
        montoTotal: 2500.00,
        montoPendiente: 1500.00,
        fechaLimitePago: DateTime.now().add(const Duration(days: 10)),
        notas: 'Préstamo personal acumulado',
        historialPartidas: [
          PartidaDeudaModelo(
            id: 'p1',
            concepto: 'Préstamo inicial para refacciones',
            monto: 1500.00,
            fecha: DateTime.now().subtract(const Duration(days: 20)),
            esAbono: false,
          ),
          PartidaDeudaModelo(
            id: 'p2',
            concepto: 'Préstamo para despensa urgente',
            monto: 1000.00,
            fecha: DateTime.now().subtract(const Duration(days: 10)),
            esAbono: false,
          ),
          PartidaDeudaModelo(
            id: 'p3',
            concepto: 'Abono en efectivo recibido',
            monto: 1000.00,
            fecha: DateTime.now().subtract(const Duration(days: 3)),
            esAbono: true,
          ),
        ],
      ),
    ];

    for (final deuda in deudasIniciales) {
      await db.insert('deudas', deuda.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final partida in deuda.historialPartidas) {
        await db.insert(
          'partidas_deuda',
          partida.toMap(idDeuda: deuda.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 3. Movimientos iniciales
    final movimientosIniciales = [
      MovimientoModelo(
        id: '1',
        titulo: 'Pago de Nómina',
        monto: 15000.00,
        fecha: DateTime.now(),
        tipo: TipoMovimiento.ingreso,
        icono: Icons.account_balance_wallet_rounded,
        categoria: 'Sueldo',
      ),
      MovimientoModelo(
        id: '2',
        titulo: 'Supermercado Mensual',
        monto: 1850.50,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        tipo: TipoMovimiento.gasto,
        icono: Icons.shopping_cart_rounded,
        categoria: 'Alimentación',
      ),
      MovimientoModelo(
        id: '3',
        titulo: 'Servicio de Internet',
        monto: 600.00,
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        tipo: TipoMovimiento.gasto,
        icono: Icons.wifi_rounded,
        categoria: 'Servicios',
      ),
    ];

    for (final mov in movimientosIniciales) {
      await db.insert('movimientos', mov.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
