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
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/nuevo_movimiento_modal.dart';
import '../componentes/nueva_meta_modal.dart';

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
  State<NavegacionPrincipalScreen> createState() => _NavegacionPrincipalScreenState();
}

class _NavegacionPrincipalScreenState extends State<NavegacionPrincipalScreen> {
  // Índice actual de la pantalla (0: Inicio, 1: Movimientos, 2: Metas, 3: Deudas)
  int _indicePestanaActual = 0;

  // Estado compartido de Metas y Objetivos de Compra
  final List<MetaModelo> _listaMetas = [
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
      montoAhorrado: 20000.00, // Cumplida
      categoria: 'Fondo de Emergencia',
      icono: Icons.shield_rounded,
      color: const Color(0xFF2E7D32),
    ),
  ];

  // Estado compartido de deudas y tarjetas con historial de pagos y compras
  final List<DeudaModelo> _listaDeudas = [
    DeudaModelo(
      id: 'tarjeta-nu',
      tituloOEntidad: 'Nu México',
      tipoDeuda: TipoDeuda.tarjetaCredito,
      montoTotal: 15000.00,
      limiteAjustado: 8000.00, // Tope personal fijado por el usuario
      montoPendiente: 3200.00,
      diaCorte: 12,
      colorTarjeta: const Color(0xFF820AD1), // Morado característico de Nu
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
      colorTarjeta: const Color(0xFFFF7700), // Naranja característico de Didi
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
      colorTarjeta: const Color(0xFF009EE3), // Azul característico de Mercado Pago
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
    DeudaModelo(
      id: 'deuda-propia-1',
      tituloOEntidad: 'Préstamo Amigo',
      tipoDeuda: TipoDeuda.debo,
      montoTotal: 2000.00,
      montoPendiente: 1000.00,
      historialPartidas: [
        PartidaDeudaModelo(
          id: 'da1',
          concepto: 'Préstamo para trámite',
          monto: 2000.00,
          fecha: DateTime.now().subtract(const Duration(days: 12)),
          esAbono: false,
        ),
      ],
    ),
  ];

  // Estado compartido de movimientos
  final List<MovimientoModelo> _listaMovimientos = [
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
        }
      }
    });

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

  // Registrar una nueva meta
  void _agregarMeta(MetaModelo nuevaMeta) {
    setState(() {
      _listaMetas.add(nuevaMeta);
    });
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
  }

  // Eliminar una meta
  void _eliminarMeta(String idMeta) {
    setState(() {
      _listaMetas.removeWhere((m) => m.id == idMeta);
    });
  }

  // Registrar una nueva deuda o tarjeta
  void _agregarDeuda(DeudaModelo nuevaDeuda) {
    setState(() {
      _listaDeudas.add(nuevaDeuda);
    });
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
  }

  // Acumular un nuevo préstamo a una persona existente
  void _acumularPrestamo(String idDeuda, String concepto, double monto, DateTime fecha) {
    setState(() {
      final index = _listaDeudas.indexWhere((d) => d.id == idDeuda);
      if (index != -1) {
        final persona = _listaDeudas[index];
        persona.acumularNuevoPrestamo(concepto: concepto, monto: monto, fecha: fecha);

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
        alRegistrarMovimiento: _agregarMovimiento,
        alPulsarNuevaMeta: _abrirModalNuevaMeta,
      ),
      const MovimientosScreen(),
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
