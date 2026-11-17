// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../modelos/movimiento_modelo.dart';
import '../modelos/deuda_modelo.dart';
import '../modelos/meta_modelo.dart';
import '../modelos/gasto_fijo_modelo.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import '../servicios/base_datos_servicio.dart';

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/modales/nuevo_movimiento_modal.dart';
import '../componentes/modales/nueva_meta_modal.dart';
import '../componentes/modales/nueva_deuda_modal.dart';
import '../componentes/modales/nuevo_gasto_fijo_modal.dart';
import '../componentes/menu/menu_lateral_drawer.dart';

// ==========================================
// IMPORTACIONES DE PANTALLAS
// ==========================================
import 'inicio_screen.dart';
import 'movimientos_screen.dart';
import 'metas_screen.dart';
import 'deudas_screen.dart';

// ==========================================
// PANTALLA CONTENEDORA: NAVEGACION PRINCIPAL
// ==========================================
class NavegacionPrincipalScreen extends StatefulWidget {
  const NavegacionPrincipalScreen({super.key});

  @override
  State<NavegacionPrincipalScreen> createState() =>
      _NavegacionPrincipalScreenState();
}

class _NavegacionPrincipalScreenState extends State<NavegacionPrincipalScreen> {
  // Clave del Scaffold para apertura programática del Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Índice actual de la pantalla (0: Inicio, 1: Movimientos, 2: Metas, 3: Deudas)
  int _indicePestanaActual = 0;

  // Sub-índice activo en la pantalla de Deudas (0: Tarjetas, 1: Me Deben, 2: Debo, 3: Gastos Fijos)
  int _subIndicePestanaDeudas = 0;

  // Listas reactivas iniciadas limpias (se nutren de SQLite)
  List<MetaModelo> _listaMetas = [];
  List<DeudaModelo> _listaDeudas = [];
  List<MovimientoModelo> _listaMovimientos = [];
  List<GastoFijoModelo> _listaGastosFijos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeBaseDatos();
  }

  // Carga asíncrona de datos desde la base de datos local SQLite
  Future<void> _cargarDatosDesdeBaseDatos() async {
    try {
      final movimientos = await BaseDatosServicio.instancia
          .obtenerMovimientos();
      final deudas = await BaseDatosServicio.instancia.obtenerDeudas();
      final metas = await BaseDatosServicio.instancia.obtenerMetas();
      final gastosFijos = await BaseDatosServicio.instancia.obtenerGastosFijos();

      if (mounted) {
        setState(() {
          _listaMovimientos = movimientos;
          _listaDeudas = deudas;
          _listaMetas = metas;
          _listaGastosFijos = gastosFijos;
        });
      }
    } catch (_) {
      // Si ocurre un error, conserva los datos en memoria
    }
  }

  // Cálculo de dinero líquido disponible real (Ingresos - Gastos en efectivo - Ahorro en metas)
  double get _dineroDisponibleReal {
    final double totalIngresos = _listaMovimientos
        .where((m) => m.tipo == TipoMovimiento.ingreso)
        .fold(0.0, (acum, m) => acum + m.monto);

    final double gastosEfectivo = _listaMovimientos
        .where((m) => m.tipo == TipoMovimiento.gasto && !m.pagadoConTarjeta)
        .fold(0.0, (acum, m) => acum + m.monto);

    final double totalEnMetas = _listaMetas.fold(
      0.0,
      (acum, meta) => acum + meta.montoAhorrado,
    );
    final double ahorroMovimientos = _listaMovimientos
        .where((m) => m.categoria == 'Ahorro / Metas')
        .fold(0.0, (acum, m) => acum + m.monto);
    final double retiroMovimientos = _listaMovimientos
        .where(
          (m) =>
              m.categoria == 'Retiro de Ahorro / Metas' ||
              m.categoria == 'Retiro de Metas',
        )
        .fold(0.0, (acum, m) => acum + m.monto);
    final double netoMovimientosMetas = ahorroMovimientos - retiroMovimientos;
    final double metasSinMovimiento = (totalEnMetas - netoMovimientosMetas)
        .clamp(0.0, double.infinity);

    return totalIngresos - gastosEfectivo - metasSinMovimiento;
  }

  // Registrar un movimiento e impactar deudas o tarjetas de crédito con historial
  void _agregarMovimiento(MovimientoModelo nuevoMovimiento) {
    setState(() {
      _listaMovimientos.insert(0, nuevoMovimiento);

      // CASO 1: Gasto pagado con Tarjeta de Crédito -> Registra cargo en la tarjeta
      if (nuevoMovimiento.pagadoConTarjeta &&
          nuevoMovimiento.idTarjetaUtilizada != null) {
        final tarjetaIndex = _listaDeudas.indexWhere(
          (d) => d.id == nuevoMovimiento.idTarjetaUtilizada,
        );
        if (tarjetaIndex != -1) {
          final tarjeta = _listaDeudas[tarjetaIndex];
          tarjeta.registrarCargoTarjeta(
            monto: nuevoMovimiento.monto,
            fecha: nuevoMovimiento.fecha,
            concepto: nuevoMovimiento.titulo,
          );
          BaseDatosServicio.instancia.actualizarDeuda(tarjeta);
        }
      }

      // CASO 2: Cobro o Abono a Deuda vinculada -> Registra abono y reduce saldo
      if (nuevoMovimiento.idDeudaAsociada != null) {
        final deudaIndex = _listaDeudas.indexWhere(
          (d) => d.id == nuevoMovimiento.idDeudaAsociada,
        );
        if (deudaIndex != -1) {
          final deuda = _listaDeudas[deudaIndex];
          deuda.registrarAbono(
            monto: nuevoMovimiento.monto,
            fecha: nuevoMovimiento.fecha,
            concepto: nuevoMovimiento.titulo,
          );
          BaseDatosServicio.instancia.actualizarDeuda(deuda);
        }
      }
    });

    // Persistir movimiento en SQLite
    BaseDatosServicio.instancia.insertarMovimiento(nuevoMovimiento);

    String mensaje;
    if (nuevoMovimiento.pagadoConTarjeta) {
      mensaje =
          'Gasto de \$${nuevoMovimiento.monto.toStringAsFixed(2)} cargado a ${nuevoMovimiento.nombreTarjetaUtilizada}';
    } else if (nuevoMovimiento.nombreDeudorAsociado != null) {
      mensaje =
          'Operación de \$${nuevoMovimiento.monto.toStringAsFixed(2)} aplicada a ${nuevoMovimiento.nombreDeudorAsociado}';
    } else {
      mensaje =
          '${nuevoMovimiento.tipo == TipoMovimiento.ingreso ? "Ingreso" : "Gasto"} registrado correctamente';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: nuevoMovimiento.pagadoConTarjeta
            ? Colors.purple.shade700
            : (nuevoMovimiento.tipo == TipoMovimiento.ingreso
                  ? ColoresApp.ingresoVerde
                  : ColoresApp.gastoRojo),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Actualizar un movimiento editado
  void _actualizarMovimiento(MovimientoModelo movimientoActualizado) {
    setState(() {
      final index = _listaMovimientos.indexWhere(
        (m) => m.id == movimientoActualizado.id,
      );
      if (index != -1) {
        _listaMovimientos[index] = movimientoActualizado;
      }
    });

    BaseDatosServicio.instancia.actualizarMovimiento(movimientoActualizado);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Movimiento "${movimientoActualizado.titulo}" actualizado',
        ),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  // Eliminar un movimiento y revertir impactos financieros vinculados
  void _eliminarMovimiento(String idMovimiento) {
    setState(() {
      final index = _listaMovimientos.indexWhere((m) => m.id == idMovimiento);
      if (index != -1) {
        final movEliminado = _listaMovimientos[index];

        // Revertir cargo de tarjeta si correspondía
        if (movEliminado.pagadoConTarjeta &&
            movEliminado.idTarjetaUtilizada != null) {
          final tarjetaIndex = _listaDeudas.indexWhere(
            (d) => d.id == movEliminado.idTarjetaUtilizada,
          );
          if (tarjetaIndex != -1) {
            final t = _listaDeudas[tarjetaIndex];
            t.montoPendiente -= movEliminado.monto;
            if (t.montoPendiente < 0) t.montoPendiente = 0;
            t.historialPartidas.removeWhere(
              (p) =>
                  p.concepto == movEliminado.titulo &&
                  p.monto == movEliminado.monto,
            );
            BaseDatosServicio.instancia.actualizarDeuda(t);
          }
        }

        // Revertir abono a deuda
        if (movEliminado.idDeudaAsociada != null) {
          final deudaIndex = _listaDeudas.indexWhere(
            (d) => d.id == movEliminado.idDeudaAsociada,
          );
          if (deudaIndex != -1) {
            final d = _listaDeudas[deudaIndex];
            d.montoPendiente += movEliminado.monto;
            d.historialPartidas.removeWhere(
              (p) => p.monto == movEliminado.monto && p.esAbono,
            );
            BaseDatosServicio.instancia.actualizarDeuda(d);
          }
        }

        _listaMovimientos.removeAt(index);
      }
    });

    BaseDatosServicio.instancia.eliminarMovimiento(idMovimiento);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Movimiento eliminado correctamente'),
        backgroundColor: ColoresApp.gastoRojo,
      ),
    );
  }

  // Registrar una nueva meta
  void _agregarMeta(MetaModelo nuevaMeta) {
    setState(() {
      _listaMetas.add(nuevaMeta);

      // Si se crea con ahorro inicial, se aparta del disponible
      if (nuevaMeta.montoAhorrado > 0) {
        final transaccion = MovimientoModelo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: 'Ahorro inicial para ${nuevaMeta.titulo}',
          monto: nuevaMeta.montoAhorrado,
          fecha: DateTime.now(),
          tipo: TipoMovimiento.gasto,
          icono: nuevaMeta.icono,
          categoria: 'Ahorro / Metas',
        );
        _listaMovimientos.insert(0, transaccion);
        BaseDatosServicio.instancia.insertarMovimiento(transaccion);
      }
    });

    BaseDatosServicio.instancia.insertarMeta(nuevaMeta);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meta "${nuevaMeta.titulo}" creada con éxito'),
        backgroundColor: nuevaMeta.color,
      ),
    );
  }

  // Abonar ahorro a una meta
  void _abonarAMeta(String idMeta, double montoAbono) {
    setState(() {
      final index = _listaMetas.indexWhere((m) => m.id == idMeta);
      if (index != -1) {
        final meta = _listaMetas[index];
        meta.abonar(montoAbono);
        BaseDatosServicio.instancia.actualizarMeta(meta);

        // Movimiento de salida de dinero disponible hacia la meta
        final transaccion = MovimientoModelo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: 'Ahorro para ${meta.titulo}',
          monto: montoAbono,
          fecha: DateTime.now(),
          tipo: TipoMovimiento.gasto,
          icono: meta.icono,
          categoria: 'Ahorro / Metas',
        );
        _listaMovimientos.insert(0, transaccion);
        BaseDatosServicio.instancia.insertarMovimiento(transaccion);
      }
    });
  }

  // Retirar ahorro de una meta para devolverlo al dinero disponible
  void _retirarDeMeta(String idMeta, double montoRetiro) {
    setState(() {
      final index = _listaMetas.indexWhere((m) => m.id == idMeta);
      if (index != -1) {
        final meta = _listaMetas[index];
        meta.retirar(montoRetiro);
        BaseDatosServicio.instancia.actualizarMeta(meta);

        // Movimiento de entrada de dinero desde la meta hacia el disponible
        final transaccion = MovimientoModelo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: 'Retiro de ahorro: ${meta.titulo}',
          monto: montoRetiro,
          fecha: DateTime.now(),
          tipo: TipoMovimiento.ingreso,
          icono: Icons.savings_outlined,
          categoria: 'Retiro de Ahorro / Metas',
        );
        _listaMovimientos.insert(0, transaccion);
        BaseDatosServicio.instancia.insertarMovimiento(transaccion);
      }
    });
  }

  // Actualizar una meta editada
  void _actualizarMeta(MetaModelo metaActualizada) {
    setState(() {
      final index = _listaMetas.indexWhere((m) => m.id == metaActualizada.id);
      if (index != -1) {
        _listaMetas[index] = metaActualizada;
      }
    });

    BaseDatosServicio.instancia.actualizarMeta(metaActualizada);
  }

  // Eliminar una meta y devolver los fondos ahorrados al dinero disponible
  void _eliminarMeta(String idMeta) {
    setState(() {
      final index = _listaMetas.indexWhere((m) => m.id == idMeta);
      if (index != -1) {
        final meta = _listaMetas[index];
        if (meta.montoAhorrado > 0) {
          final transaccionReintegro = MovimientoModelo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            titulo: 'Reintegro por meta eliminada: ${meta.titulo}',
            monto: meta.montoAhorrado,
            fecha: DateTime.now(),
            tipo: TipoMovimiento.ingreso,
            icono: Icons.savings_outlined,
            categoria: 'Retiro de Ahorro / Metas',
          );
          _listaMovimientos.insert(0, transaccionReintegro);
          BaseDatosServicio.instancia.insertarMovimiento(transaccionReintegro);
        }
        _listaMetas.removeAt(index);
      }
    });

    BaseDatosServicio.instancia.eliminarMeta(idMeta);
  }

  // Registrar una nueva deuda o tarjeta
  void _agregarDeuda(DeudaModelo nuevaDeuda) {
    setState(() {
      _listaDeudas.add(nuevaDeuda);

      // Si presté dinero a alguien (Me Deben), sale de mi efectivo disponible
      if (nuevaDeuda.tipoDeuda == TipoDeuda.meDeben &&
          nuevaDeuda.montoPendiente > 0) {
        final transaccion = MovimientoModelo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: 'Préstamo a ${nuevaDeuda.tituloOEntidad}',
          monto: nuevaDeuda.montoPendiente,
          fecha: DateTime.now(),
          tipo: TipoMovimiento.gasto,
          icono: Icons.handshake_rounded,
          categoria: 'Préstamo Otorgado',
          idDeudaAsociada: nuevaDeuda.id,
          nombreDeudorAsociado: nuevaDeuda.tituloOEntidad,
        );
        _listaMovimientos.insert(0, transaccion);
        BaseDatosServicio.instancia.insertarMovimiento(transaccion);
      }
    });

    BaseDatosServicio.instancia.insertarDeuda(nuevaDeuda);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${nuevaDeuda.tituloOEntidad} agregada exitosamente'),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  // Actualizar tarjeta con todos sus parámetros editados
  void _actualizarTarjeta(DeudaModelo tarjetaActualizada) {
    setState(() {
      final index = _listaDeudas.indexWhere(
        (d) => d.id == tarjetaActualizada.id,
      );
      if (index != -1) {
        _listaDeudas[index] = tarjetaActualizada;
      }
    });

    BaseDatosServicio.instancia.actualizarDeuda(tarjetaActualizada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Parámetros de ${tarjetaActualizada.tituloOEntidad} actualizados',
        ),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  // Actualizar una deuda personal
  void _actualizarDeudaPersona(DeudaModelo deudaActualizada) {
    setState(() {
      final index = _listaDeudas.indexWhere((d) => d.id == deudaActualizada.id);
      if (index != -1) {
        _listaDeudas[index] = deudaActualizada;
      }
    });

    BaseDatosServicio.instancia.actualizarDeuda(deudaActualizada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registro de "${deudaActualizada.tituloOEntidad}" actualizado',
        ),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  // Eliminar una deuda o tarjeta
  void _eliminarDeuda(String idDeuda) {
    setState(() {
      _listaDeudas.removeWhere((d) => d.id == idDeuda);
    });

    BaseDatosServicio.instancia.eliminarDeuda(idDeuda);
  }

  // Acumular un nuevo préstamo a una persona existente
  void _acumularPrestamo(
    String idDeuda,
    String concepto,
    double monto,
    DateTime fecha,
  ) {
    setState(() {
      final index = _listaDeudas.indexWhere((d) => d.id == idDeuda);
      if (index != -1) {
        final persona = _listaDeudas[index];
        persona.acumularNuevoPrestamo(
          concepto: concepto,
          monto: monto,
          fecha: fecha,
        );
        BaseDatosServicio.instancia.actualizarDeuda(persona);

        // Si le presté más dinero, se descuenta de mi dinero disponible
        if (persona.tipoDeuda == TipoDeuda.meDeben) {
          final transaccion = MovimientoModelo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            titulo: 'Préstamo adicional a ${persona.tituloOEntidad}',
            monto: monto,
            fecha: fecha,
            tipo: TipoMovimiento.gasto,
            icono: Icons.handshake_rounded,
            categoria: 'Préstamo Otorgado',
            idDeudaAsociada: persona.id,
            nombreDeudorAsociado: persona.tituloOEntidad,
          );
          _listaMovimientos.insert(0, transaccion);
          BaseDatosServicio.instancia.insertarMovimiento(transaccion);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se acumularon \$${monto.toStringAsFixed(2)} a ${persona.tituloOEntidad} (Total: \$${persona.montoPendiente.toStringAsFixed(2)})',
            ),
            backgroundColor: ColoresApp.primarioVerde,
          ),
        );
      }
    });
  }

  // Modificar la fecha/día de corte de una tarjeta existente
  void _actualizarDiaCorteTarjeta(String idTarjeta, int nuevoDiaCorte) {
    setState(() {
      final index = _listaDeudas.indexWhere((d) => d.id == idTarjeta);
      if (index != -1) {
        _listaDeudas[index].diaCorte = nuevoDiaCorte;
        BaseDatosServicio.instancia.actualizarDeuda(_listaDeudas[index]);
      }
    });
  }

  // Abonar a una deuda desde la pantalla de deudas
  void _abonarADeuda(String idDeuda, double montoAbono) {
    final deudaIndex = _listaDeudas.indexWhere((d) => d.id == idDeuda);
    if (deudaIndex != -1) {
      final deuda = _listaDeudas[deudaIndex];
      final bool esMeDeben = deuda.tipoDeuda == TipoDeuda.meDeben;
      final bool esTarjeta = deuda.tipoDeuda == TipoDeuda.tarjetaCredito;

      final transaccion = MovimientoModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: esTarjeta
            ? 'Pago a tarjeta ${deuda.tituloOEntidad}'
            : (esMeDeben
                  ? 'Abono de ${deuda.tituloOEntidad}'
                  : 'Pago a ${deuda.tituloOEntidad}'),
        monto: montoAbono,
        fecha: DateTime.now(),
        tipo: esMeDeben ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
        icono: esTarjeta
            ? Icons.credit_card_rounded
            : (esMeDeben
                  ? Icons.handshake_rounded
                  : Icons.money_off_csred_rounded),
        categoria: esTarjeta
            ? 'Pago de Deuda / Tarjeta'
            : (esMeDeben ? 'Cobro de Deuda' : 'Pago de Deuda / Tarjeta'),
        idDeudaAsociada: deuda.id,
        nombreDeudorAsociado: deuda.tituloOEntidad,
      );

      _agregarMovimiento(transaccion);
    }
  }

  // Abrir ventana modal (Dialog) de nuevo movimiento
  void _abrirModalRegistroCentral() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NuevoMovimientoModal(
        tipoInicial: TipoMovimiento.gasto,
        listaDeudasActivas: _listaDeudas,
        dineroDisponible: _dineroDisponibleReal,
        alGuardarMovimiento: _agregarMovimiento,
      ),
    );
  }

  // Abrir ventana modal (Dialog) de nueva meta desde Inicio
  void _abrirModalNuevaMeta() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NuevaMetaModal(alGuardarMeta: _agregarMeta),
    );
  }

  // ==========================================
  // GESTION DE GASTOS FIJOS Y SUSCRIPCIONES
  // ==========================================
  void _mostrarModalNuevoGastoFijo([GastoFijoModelo? gastoFijoParaEditar]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NuevoGastoFijoModal(
        gastoFijoParaEditar: gastoFijoParaEditar,
        listaTarjetas: _listaDeudas,
        alGuardarGastoFijo: (gasto) {
          if (gastoFijoParaEditar != null) {
            _actualizarGastoFijo(gasto);
          } else {
            _agregarGastoFijo(gasto);
          }
        },
      ),
    );
  }

  void _agregarGastoFijo(GastoFijoModelo nuevoGastoFijo) {
    setState(() {
      _listaGastosFijos.add(nuevoGastoFijo);
      _listaGastosFijos.sort((a, b) => a.diaPago.compareTo(b.diaPago));
    });
    BaseDatosServicio.instancia.insertarGastoFijo(nuevoGastoFijo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gasto fijo "${nuevoGastoFijo.nombre}" registrado'),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  void _actualizarGastoFijo(GastoFijoModelo gastoActualizado) {
    setState(() {
      final index = _listaGastosFijos.indexWhere((g) => g.id == gastoActualizado.id);
      if (index != -1) {
        _listaGastosFijos[index] = gastoActualizado;
        _listaGastosFijos.sort((a, b) => a.diaPago.compareTo(b.diaPago));
      }
    });
    BaseDatosServicio.instancia.actualizarGastoFijo(gastoActualizado);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gasto fijo "${gastoActualizado.nombre}" actualizado'),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  void _eliminarGastoFijo(GastoFijoModelo gastoAEliminar) {
    setState(() {
      _listaGastosFijos.removeWhere((g) => g.id == gastoAEliminar.id);
    });
    BaseDatosServicio.instancia.eliminarGastoFijo(gastoAEliminar.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${gastoAEliminar.nombre}" eliminado de gastos fijos'),
        backgroundColor: ColoresApp.gastoRojo,
      ),
    );
  }

  // Marcar gasto fijo como pagado en 1 toque y registrar el movimiento
  void _marcarGastoFijoPagado(GastoFijoModelo gasto) {
    setState(() {
      gasto.marcarPagadoMesActual();
    });
    BaseDatosServicio.instancia.actualizarGastoFijo(gasto);

    // Generar automáticamente el movimiento financiero correspondiente
    final movimientoPago = MovimientoModelo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: 'Pago fijo: ${gasto.nombre}',
      monto: gasto.monto,
      fecha: DateTime.now(),
      tipo: TipoMovimiento.gasto,
      icono: gasto.icono,
      categoria: gasto.categoria,
      pagadoConTarjeta: gasto.pagarConTarjeta,
      idTarjetaUtilizada: gasto.idTarjeta,
      nombreTarjetaUtilizada: gasto.nombreTarjeta,
    );

    _agregarMovimiento(movimientoPago);
  }

  // ==========================================
  // APERTURA DE MODAL DE DEUDA SEGUN TIPO
  // ==========================================
  void _abrirModalNuevaDeudaSegunTipo(TipoDeuda tipoInicial) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NuevaDeudaModal(
        tipoInicial: tipoInicial,
        listaDeudasExistentes: _listaDeudas,
        alGuardarDeuda: _agregarDeuda,
        alAcumularDeuda: _acumularPrestamo,
      ),
    );
  }

  // ==========================================
  // CONFIGURACION DINAMICA DEL BOTON FLOTANTE
  // ==========================================
  // Color contextual según la pestaña o subpestaña actual
  Color get _colorBotonFlotante {
    switch (_indicePestanaActual) {
      case 2: // Metas
        return const Color(0xFFE65100);
      case 3: // Deudas y Tarjetas
        switch (_subIndicePestanaDeudas) {
          case 0:
            return Colors.purple.shade700; // Tarjetas
          case 1:
            return ColoresApp.primarioVerde; // Me Deben (Préstamos)
          case 2:
            return ColoresApp.gastoRojo; // Debo (Deudas)
          case 3:
            return const Color(0xFF1976D2); // Gastos Fijos
          default:
            return ColoresApp.primarioVerde;
        }
      case 0: // Inicio
      case 1: // Movimientos
      default:
        return ColoresApp.primarioVerde;
    }
  }

  // Ícono contextual según la pestaña o subpestaña actual
  IconData get _iconoBotonFlotante {
    switch (_indicePestanaActual) {
      case 2: // Metas
        return Icons.flag_rounded;
      case 3: // Deudas y Tarjetas
        switch (_subIndicePestanaDeudas) {
          case 0:
            return Icons.credit_card_rounded;
          case 1:
            return Icons.handshake_rounded;
          case 2:
            return Icons.money_off_csred_rounded;
          case 3:
            return Icons.repeat_rounded;
          default:
            return Icons.add_rounded;
        }
      case 0: // Inicio
      case 1: // Movimientos
      default:
        return Icons.add_rounded;
    }
  }

  // Tooltip descriptivo según el contexto
  String get _tooltipBotonFlotante {
    switch (_indicePestanaActual) {
      case 2:
        return 'Nueva Meta';
      case 3:
        switch (_subIndicePestanaDeudas) {
          case 0:
            return 'Nueva Tarjeta';
          case 1:
            return 'Nuevo Préstamo';
          case 2:
            return 'Nueva Deuda';
          case 3:
            return 'Nuevo Gasto Fijo';
          default:
            return 'Nuevo Registro';
        }
      case 0:
      case 1:
      default:
        return 'Nuevo Movimiento';
    }
  }

  // Acción disparada al presionar el botón flotante adaptativo
  void _ejecutarAccionBotonFlotante() {
    switch (_indicePestanaActual) {
      case 2: // Metas
        _abrirModalNuevaMeta();
        break;
      case 3: // Deudas y Tarjetas
        switch (_subIndicePestanaDeudas) {
          case 0:
            _abrirModalNuevaDeudaSegunTipo(TipoDeuda.tarjetaCredito);
            break;
          case 1:
            _abrirModalNuevaDeudaSegunTipo(TipoDeuda.meDeben);
            break;
          case 2:
            _abrirModalNuevaDeudaSegunTipo(TipoDeuda.debo);
            break;
          case 3:
            _mostrarModalNuevoGastoFijo();
            break;
          default:
            _abrirModalRegistroCentral();
        }
        break;
      case 0: // Inicio
      case 1: // Movimientos
      default:
        _abrirModalRegistroCentral();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas con el estado compartido
    final List<Widget> pantallas = [
      InicioScreen(
        listaMovimientos: _listaMovimientos,
        listaDeudas: _listaDeudas,
        listaMetas: _listaMetas,
        listaGastosFijos: _listaGastosFijos,
        dineroDisponible: _dineroDisponibleReal,
        alRegistrarMovimiento: _agregarMovimiento,
        alPulsarNuevaMeta: _abrirModalNuevaMeta,
        alAbrirMenuLateral: () => _scaffoldKey.currentState?.openDrawer(),
        alPulsarVerTodosMovimientos: () => setState(() => _indicePestanaActual = 1),
      ),
      MovimientosScreen(
        listaMovimientos: _listaMovimientos,
        listaDeudas: _listaDeudas,
        alEliminarMovimiento: _eliminarMovimiento,
        alActualizarMovimiento: _actualizarMovimiento,
        alPulsarNuevoMovimiento: _abrirModalRegistroCentral,
        alAbrirMenuLateral: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      MetasScreen(
        listaMetas: _listaMetas,
        alCrearMeta: _agregarMeta,
        alActualizarMeta: _actualizarMeta,
        alEliminarMeta: _eliminarMeta,
        alAbonarMeta: _abonarAMeta,
        alRetirarMeta: _retirarDeMeta,
        alAbrirMenuLateral: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      DeudasScreen(
        listaDeudas: _listaDeudas,
        listaGastosFijos: _listaGastosFijos,
        alAgregarDeuda: _agregarDeuda,
        alActualizarTarjeta: _actualizarTarjeta,
        alActualizarDeudaPersona: _actualizarDeudaPersona,
        alEliminarDeuda: _eliminarDeuda,
        alAbonarDeuda: _abonarADeuda,
        alEditarDiaCorte: _actualizarDiaCorteTarjeta,
        alAcumularPrestamo: _acumularPrestamo,
        alPulsarNuevoGastoFijo: () => _mostrarModalNuevoGastoFijo(),
        alMarcarGastoFijoPagado: _marcarGastoFijoPagado,
        alEditarGastoFijo: (g) => _mostrarModalNuevoGastoFijo(g),
        alEliminarGastoFijo: _eliminarGastoFijo,
        alCambiarSubPestana: (subIndice) =>
            setState(() => _subIndicePestanaDeudas = subIndice),
        alAbrirMenuLateral: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColoresApp.fondo(context),
      drawer: MenuLateralDrawer(
        dineroDisponible: _dineroDisponibleReal,
        indicePestanaActual: _indicePestanaActual,
        alSeleccionarPestana: (indice) {
          setState(() => _indicePestanaActual = indice);
        },
        alAbrirPanelFinanzas: () => setState(() => _indicePestanaActual = 0),
        alRegistrarMovimiento: _abrirModalRegistroCentral,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: IndexedStack(
            index: _indicePestanaActual,
            children: pantallas,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ejecutarAccionBotonFlotante,
        backgroundColor: _colorBotonFlotante,
        tooltip: _tooltipBotonFlotante,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(_iconoBotonFlotante, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: ColoresApp.tarjeta(context),
        elevation: 10,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lado Izquierdo: Inicio y Movimientos
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _BotonNavegacionItem(
                            icono: Icons.home_rounded,
                            etiqueta: 'Inicio',
                            estaSeleccionado: _indicePestanaActual == 0,
                            alPresionar: () => setState(() => _indicePestanaActual = 0),
                          ),
                        ),
                        Expanded(
                          child: _BotonNavegacionItem(
                            icono: Icons.receipt_long_rounded,
                            etiqueta: 'Movimientos',
                            estaSeleccionado: _indicePestanaActual == 1,
                            alPresionar: () => setState(() => _indicePestanaActual = 1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Espacio central para el FloatingActionButton
                  const SizedBox(width: 48),

                  // Lado Derecho: Metas y Deudas
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _BotonNavegacionItem(
                            icono: Icons.flag_rounded,
                            etiqueta: 'Metas',
                            estaSeleccionado: _indicePestanaActual == 2,
                            alPresionar: () => setState(() => _indicePestanaActual = 2),
                          ),
                        ),
                        Expanded(
                          child: _BotonNavegacionItem(
                            icono: Icons.account_balance_wallet_rounded,
                            etiqueta: 'Deudas',
                            estaSeleccionado: _indicePestanaActual == 3,
                            alPresionar: () => setState(() => _indicePestanaActual = 3),
                          ),
                        ),
                      ],
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

// ==========================================
// SUBCOMPONENTE PRIVADO: BOTON DE LA BARRA INFERIOR
// ==========================================
class _BotonNavegacionItem extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool estaSeleccionado;
  final VoidCallback alPresionar;

  const _BotonNavegacionItem({
    required this.icono,
    required this.etiqueta,
    required this.estaSeleccionado,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorActual = estaSeleccionado
        ? ColoresApp.primarioVerde
        : ColoresApp.textoSecundario;

    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: colorActual, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: estaSeleccionado
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: colorActual,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
