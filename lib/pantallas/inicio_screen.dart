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
import '../componentes/balance_card.dart';
import '../componentes/movimiento_item_tile.dart';
import '../componentes/nuevo_movimiento_modal.dart';
import '../componentes/deudas_resumen_card.dart';

// ==========================================
// PANTALLA PRINCIPAL: INICIO
// ==========================================
class InicioScreen extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final Function(MovimientoModelo) alRegistrarMovimiento;
  final VoidCallback? alPulsarNuevaMeta;

  const InicioScreen({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    required this.alRegistrarMovimiento,
    this.alPulsarNuevaMeta,
  });

  // Métodos de cálculo dinámico para el balance
  double get _totalIngresos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acumulado, m) => acumulado + m.monto);

  double get _totalGastos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (acumulado, m) => acumulado + m.monto);

  double get _saldoTotal => _totalIngresos - _totalGastos;

  // Función para abrir el modal de nuevo movimiento
  void _mostrarModalRegistro(BuildContext context, TipoMovimiento tipoInicial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevoMovimientoModal(
        tipoInicial: tipoInicial,
        listaDeudasActivas: listaDeudas,
        alGuardarMovimiento: alRegistrarMovimiento,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoClaro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con saludo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hola de nuevo 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColoresApp.textoSecundario,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mi Resumen Financiero',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: ColoresApp.primarioVerde.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: ColoresApp.primarioVerde,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tarjeta principal de balance reactivo
              BalanceCard(
                saldoTotal: _saldoTotal,
                ingresosMes: _totalIngresos,
                gastosMes: _totalGastos,
              ),
              const SizedBox(height: 20),

              // Tarjeta de cuentas por cobrar y deudas activas
              DeudasResumenCard(
                listaDeudas: listaDeudas,
                alPulsarVerDetalles: () {},
              ),
              const SizedBox(height: 24),

              // Botones de acciones rápidas
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BotonAccionRapidaItem(
                    icono: Icons.add_rounded,
                    etiqueta: 'Ingreso',
                    colorFondo: ColoresApp.ingresoVerde,
                    alPresionar: () => _mostrarModalRegistro(context, TipoMovimiento.ingreso),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.remove_rounded,
                    etiqueta: 'Gasto',
                    colorFondo: ColoresApp.gastoRojo,
                    alPresionar: () => _mostrarModalRegistro(context, TipoMovimiento.gasto),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.credit_card_rounded,
                    etiqueta: 'Tarjeta',
                    colorFondo: Colors.purple,
                    alPresionar: () => _mostrarModalRegistro(context, TipoMovimiento.gasto),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.flag_rounded,
                    etiqueta: 'Meta',
                    colorFondo: ColoresApp.metaNaranja,
                    alPresionar: alPulsarNuevaMeta ?? () {},
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Encabezado de movimientos recientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Movimientos Recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.textoPrincipal,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de movimientos recientes o estado vacío
              if (listaMovimientos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: ColoresApp.textoSecundario),
                      SizedBox(height: 8),
                      Text(
                        'Aún no hay movimientos registrados',
                        style: TextStyle(color: ColoresApp.textoSecundario),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listaMovimientos.length,
                  itemBuilder: (context, index) {
                    final movimiento = listaMovimientos[index];
                    return MovimientoItemTile(
                      movimiento: movimiento,
                      alPulsar: () {},
                    );
                  },
                ),
              // Espacio inferior para no tapar con el botón flotante y bottom app bar
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: BOTON DE ACCION RAPIDA
// ==========================================
class _BotonAccionRapidaItem extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final Color colorFondo;
  final VoidCallback alPresionar;

  const _BotonAccionRapidaItem({
    required this.icono,
    required this.etiqueta,
    required this.colorFondo,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorFondo.withValues(alpha: 0.12),
            child: Icon(icono, color: colorFondo, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColoresApp.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
