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

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import '../servicios/base_datos_servicio.dart';

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/nuevo_movimiento_modal.dart';
import '../componentes/nueva_meta_modal.dart';
import '../componentes/menu_lateral_drawer.dart';

// ==========================================
// IMPORTACIONES DE PANTALLAS
// ==========================================
import 'inicio_screen.dart';
import 'movimientos_screen.dart';
import 'metas_screen.dart';
import 'deudas_screen.dart';
import 'finanzas_screen.dart';

// ==========================================
// PANTALLA CONTENEDORA: NAVEGACION PRINCIPAL
// ==========================================
class NavegacionPrincipalScreen extends StatefulWidget {
  const NavegacionPrincipalScreen({super.key});

  @override
  State<NavegacionPrincipalScreen> createState() => _NavegacionPrincipalScreenState();
}

class _NavegacionPrincipalScreenState extends State<NavegacionPrincipalScreen> {
  // Clave del Scaffold para apertura programática del Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Índice actual de la pantalla (0: Inicio, 1: Movimientos, 2: Metas, 3: Deudas)
  int _indicePestanaActual = 0;

  // Listas reactivas iniciadas limpias (se nutren de SQLite)
  List<MetaModelo> _listaMetas = [];
  List<DeudaModelo> _listaDeudas = [];
  List<MovimientoModelo> _listaMovimientos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeBaseDatos();
  }

  // Carga asíncrona de datos desde la base de datos local SQLite
  Future<void> _cargarDatosDesdeBaseDatos() async {
    try {
      final movimientos = await BaseDatosServicio.instancia.obtenerMovimientos();
      final deudas = await BaseDatosServicio.instancia.obtenerDeudas();
      final metas = await BaseDatosServicio.instancia.obtenerMetas();

      if (mounted) {
        setState(() {
          _listaMovimientos = movimientos;
          _listaDeudas = deudas;
          _listaMetas = metas;
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

    final double totalEnMetas = _listaMetas.fold(0.0, (acum, meta) => acum + meta.montoAhorrado);

    return totalIngresos - gastosEfectivo - totalEnMetas;
  }

  // Registrar un movimiento e impactar deudas o tarjetas de crédito con historial
  void _agregarMovimiento(MovimientoModelo nuevoMovimiento) {
    setState(() {
      _listaMovimientos.insert(0, nuevoMovimiento);

      // CASO 1: Gasto pagado con Tarjeta de Crédito -> Registra cargo en la tarjeta
      if (nuevoMovimiento.pagadoConTarjeta && nuevoMovimiento.idTarjetaUtilizada != null) {
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
      mensaje = 'Gasto de \$${nuevoMovimiento.monto.toStringAsFixed(2)} cargado a ${nuevoMovimiento.nombreTarjetaUtilizada}';
    } else if (nuevoMovimiento.nombreDeudorAsociado != null) {
      mensaje = 'Operación de \$${nuevoMovimiento.monto.toStringAsFixed(2)} aplicada a ${nuevoMovimiento.nombreDeudorAsociado}';
    } else {
      mensaje = '${nuevoMovimiento.tipo == TipoMovimiento.ingreso ? "Ingreso" : "Gasto"} registrado correctamente';
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
      final index = _listaMovimientos.indexWhere((m) => m.id == movimientoActualizado.id);
      if (index != -1) {
        _listaMovimientos[index] = movimientoActualizado;
      }
    });

    BaseDatosServicio.instancia.actualizarMovimiento(movimientoActualizado);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Movimiento "${movimientoActualizado.titulo}" actualizado'),
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
        if (movEliminado.pagadoConTarjeta && movEliminado.idTarjetaUtilizada != null) {
          final tarjetaIndex = _listaDeudas.indexWhere((d) => d.id == movEliminado.idTarjetaUtilizada);
          if (tarjetaIndex != -1) {
            final t = _listaDeudas[tarjetaIndex];
            t.montoPendiente -= movEliminado.monto;
            if (t.montoPendiente < 0) t.montoPendiente = 0;
            t.historialPartidas.removeWhere((p) => p.concepto == movEliminado.titulo && p.monto == movEliminado.monto);
            BaseDatosServicio.instancia.actualizarDeuda(t);
          }
        }

        // Revertir abono a deuda
        if (movEliminado.idDeudaAsociada != null) {
          final deudaIndex = _listaDeudas.indexWhere((d) => d.id == movEliminado.idDeudaAsociada);
          if (deudaIndex != -1) {
            final d = _listaDeudas[deudaIndex];
            d.montoPendiente += movEliminado.monto;
            d.historialPartidas.removeWhere((p) => p.monto == movEliminado.monto && p.esAbono);
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
        _listaMetas[index].abonar(montoAbono);
        BaseDatosServicio.instancia.actualizarMeta(_listaMetas[index]);
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

  // Eliminar una meta
  void _eliminarMeta(String idMeta) {
    setState(() {
      _listaMetas.removeWhere((m) => m.id == idMeta);
    });

    BaseDatosServicio.instancia.eliminarMeta(idMeta);
  }

  // Registrar una nueva deuda o tarjeta
  void _agregarDeuda(DeudaModelo nuevaDeuda) {
    setState(() {
      _listaDeudas.add(nuevaDeuda);
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
      final index = _listaDeudas.indexWhere((d) => d.id == tarjetaActualizada.id);
      if (index != -1) {
        _listaDeudas[index] = tarjetaActualizada;
      }
    });

    BaseDatosServicio.instancia.actualizarDeuda(tarjetaActualizada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Parámetros de ${tarjetaActualizada.tituloOEntidad} actualizados'),
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
        content: Text('Registro de "${deudaActualizada.tituloOEntidad}" actualizado'),
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
  void _acumularPrestamo(String idDeuda, String concepto, double monto, DateTime fecha) {
    setState(() {
      final index = _listaDeudas.indexWhere((d) => d.id == idDeuda);
      if (index != -1) {
        final persona = _listaDeudas[index];
        persona.acumularNuevoPrestamo(concepto: concepto, monto: monto, fecha: fecha);
        BaseDatosServicio.instancia.actualizarDeuda(persona);

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
            : (esMeDeben ? 'Abono de ${deuda.tituloOEntidad}' : 'Pago a ${deuda.tituloOEntidad}'),
        monto: montoAbono,
        fecha: DateTime.now(),
        tipo: esMeDeben ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
        icono: esTarjeta
            ? Icons.credit_card_rounded
            : (esMeDeben ? Icons.handshake_rounded : Icons.money_off_csred_rounded),
        categoria: esTarjeta
            ? 'Pago de Deuda / Tarjeta'
            : (esMeDeben ? 'Cobro de Deuda' : 'Pago de Deuda / Tarjeta'),
        idDeudaAsociada: deuda.id,
        nombreDeudorAsociado: deuda.tituloOEntidad,
      );

      _agregarMovimiento(transaccion);
    }
  }

  // Navegar a la pantalla de análisis financiero y gráficas
  void _abrirPanelFinanzas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FinanzasScreen(
          listaMovimientos: _listaMovimientos,
          listaDeudas: _listaDeudas,
          listaMetas: _listaMetas,
        ),
      ),
    );
  }

  // Abrir el modal central de nuevo movimiento
  void _abrirModalRegistroCentral() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevoMovimientoModal(
        tipoInicial: TipoMovimiento.gasto,
        listaDeudasActivas: _listaDeudas,
        dineroDisponible: _dineroDisponibleReal,
        alGuardarMovimiento: _agregarMovimiento,
      ),
    );
  }

  // Abrir modal de nueva meta desde Inicio
  void _abrirModalNuevaMeta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevaMetaModal(
        alGuardarMeta: _agregarMeta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas con el estado compartido
    final List<Widget> pantallas = [
      InicioScreen(
        listaMovimientos: _listaMovimientos,
        listaDeudas: _listaDeudas,
        dineroDisponible: _dineroDisponibleReal,
        alRegistrarMovimiento: _agregarMovimiento,
        alPulsarNuevaMeta: _abrirModalNuevaMeta,
        alAbrirPanelFinanzas: _abrirPanelFinanzas,
      ),
      MovimientosScreen(
        listaMovimientos: _listaMovimientos,
        listaDeudas: _listaDeudas,
        alEliminarMovimiento: _eliminarMovimiento,
        alActualizarMovimiento: _actualizarMovimiento,
        alPulsarNuevoMovimiento: _abrirModalRegistroCentral,
      ),
      MetasScreen(
        listaMetas: _listaMetas,
        alCrearMeta: _agregarMeta,
        alActualizarMeta: _actualizarMeta,
        alEliminarMeta: _eliminarMeta,
        alAbonarMeta: _abonarAMeta,
      ),
      DeudasScreen(
        listaDeudas: _listaDeudas,
        alAgregarDeuda: _agregarDeuda,
        alActualizarTarjeta: _actualizarTarjeta,
        alActualizarDeudaPersona: _actualizarDeudaPersona,
        alEliminarDeuda: _eliminarDeuda,
        alAbonarDeuda: _abonarADeuda,
        alEditarDiaCorte: _actualizarDiaCorteTarjeta,
        alAcumularPrestamo: _acumularPrestamo,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuLateralDrawer(
        dineroDisponible: _dineroDisponibleReal,
        indicePestanaActual: _indicePestanaActual,
        alSeleccionarPestana: (indice) => setState(() => _indicePestanaActual = indice),
        alAbrirPanelFinanzas: _abrirPanelFinanzas,
        alRegistrarMovimiento: _abrirModalRegistroCentral,
      ),
      body: pantallas[_indicePestanaActual],
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalRegistroCentral,
        backgroundColor: ColoresApp.primarioVerde,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lado Izquierdo: Inicio y Movimientos
              Row(
                children: [
                  _BotonNavegacionItem(
                    icono: Icons.home_rounded,
                    etiqueta: 'Inicio',
                    estaSeleccionado: _indicePestanaActual == 0,
                    alPresionar: () => setState(() => _indicePestanaActual = 0),
                  ),
                  _BotonNavegacionItem(
                    icono: Icons.receipt_long_rounded,
                    etiqueta: 'Movimientos',
                    estaSeleccionado: _indicePestanaActual == 1,
                    alPresionar: () => setState(() => _indicePestanaActual = 1),
                  ),
                ],
              ),

              // Espacio central para el FloatingActionButton
              const SizedBox(width: 48),

              // Lado Derecho: Metas y Deudas
              Row(
                children: [
                  _BotonNavegacionItem(
                    icono: Icons.flag_rounded,
                    etiqueta: 'Metas',
                    estaSeleccionado: _indicePestanaActual == 2,
                    alPresionar: () => setState(() => _indicePestanaActual = 2),
                  ),
                  _BotonNavegacionItem(
                    icono: Icons.account_balance_wallet_rounded,
                    etiqueta: 'Deudas',
                    estaSeleccionado: _indicePestanaActual == 3,
                    alPresionar: () => setState(() => _indicePestanaActual = 3),
                  ),
                ],
              ),
            ],
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
    final Color colorActual =
        estaSeleccionado ? ColoresApp.primarioVerde : ColoresApp.textoSecundario;

    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: colorActual, size: 22),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.w500,
                color: colorActual,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
