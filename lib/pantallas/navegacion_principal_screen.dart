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

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/nuevo_movimiento_modal.dart';

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

  // Estado compartido de deudas y tarjetas
  final List<DeudaModelo> _listaDeudas = [
    DeudaModelo(
      id: 'deuda-1',
      tituloOEntidad: 'Juan Pérez',
      tipoDeuda: TipoDeuda.meDeben,
      montoTotal: 2500.00,
      montoPendiente: 1500.00,
      fechaLimitePago: DateTime.now().add(const Duration(days: 10)),
      notas: 'Préstamo personal',
    ),
    DeudaModelo(
      id: 'deuda-2',
      tituloOEntidad: 'Carlos Gómez',
      tipoDeuda: TipoDeuda.meDeben,
      montoTotal: 3000.00,
      montoPendiente: 3000.00,
      fechaLimitePago: DateTime.now().add(const Duration(days: 20)),
    ),
    DeudaModelo(
      id: 'tarjeta-1',
      tituloOEntidad: 'Tarjeta BBVA Oro',
      tipoDeuda: TipoDeuda.tarjetaCredito,
      montoTotal: 20000.00,
      montoPendiente: 4350.00,
      diaCorte: 15,
      fechaLimitePago: DateTime.now().add(const Duration(days: 8)),
    ),
    DeudaModelo(
      id: 'deuda-propia-1',
      tituloOEntidad: 'Préstamo Familiar',
      tipoDeuda: TipoDeuda.debo,
      montoTotal: 5000.00,
      montoPendiente: 2000.00,
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

  // Registrar un movimiento e impactar la deuda correspondiente si aplica
  void _agregarMovimiento(MovimientoModelo nuevoMovimiento) {
    setState(() {
      _listaMovimientos.insert(0, nuevoMovimiento);

      // Si tiene deuda vinculada, restamos del monto pendiente
      if (nuevoMovimiento.idDeudaAsociada != null) {
        final deudaIndex = _listaDeudas.indexWhere(
          (d) => d.id == nuevoMovimiento.idDeudaAsociada,
        );
        if (deudaIndex != -1) {
          final deuda = _listaDeudas[deudaIndex];
          deuda.montoPendiente -= nuevoMovimiento.monto;
          if (deuda.montoPendiente < 0) deuda.montoPendiente = 0;
        }
      }
    });

    final bool esCobroOPago = nuevoMovimiento.nombreDeudorAsociado != null;
    final String mensaje = esCobroOPago
        ? 'Operación de \$${nuevoMovimiento.monto.toStringAsFixed(2)} aplicada a ${nuevoMovimiento.nombreDeudorAsociado}'
        : '${nuevoMovimiento.tipo == TipoMovimiento.ingreso ? "Ingreso" : "Gasto"} registrado correctamente';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: nuevoMovimiento.tipo == TipoMovimiento.ingreso
            ? ColoresApp.ingresoVerde
            : ColoresApp.gastoRojo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Registrar una nueva deuda o tarjeta
  void _agregarDeuda(DeudaModelo nuevaDeuda) {
    setState(() {
      _listaDeudas.add(nuevaDeuda);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${nuevaDeuda.tituloOEntidad} añadida exitosamente'),
        backgroundColor: ColoresApp.primarioVerde,
      ),
    );
  }

  // Abonar a una deuda desde la pantalla de deudas
  void _abonarADeuda(String idDeuda, double montoAbono) {
    final deudaIndex = _listaDeudas.indexWhere((d) => d.id == idDeuda);
    if (deudaIndex != -1) {
      final deuda = _listaDeudas[deudaIndex];
      final bool esMeDeben = deuda.tipoDeuda == TipoDeuda.meDeben;

      // Creamos la transacción automática en el historial
      final transaccion = MovimientoModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: esMeDeben ? 'Abono de ${deuda.tituloOEntidad}' : 'Pago a ${deuda.tituloOEntidad}',
        monto: montoAbono,
        fecha: DateTime.now(),
        tipo: esMeDeben ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
        icono: esMeDeben ? Icons.handshake_rounded : Icons.credit_card_rounded,
        categoria: esMeDeben ? 'Cobro de Deuda' : 'Pago de Deuda / Tarjeta',
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

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas con el estado compartido
    final List<Widget> pantallas = [
      InicioScreen(
        listaMovimientos: _listaMovimientos,
        listaDeudas: _listaDeudas,
        alRegistrarMovimiento: _agregarMovimiento,
      ),
      const MovimientosScreen(),
      const MetasScreen(),
      DeudasScreen(
        listaDeudas: _listaDeudas,
        alAgregarDeuda: _agregarDeuda,
        alAbonarDeuda: _abonarADeuda,
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
                    icono: Icons.account_balance_wallet_outlined,
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
