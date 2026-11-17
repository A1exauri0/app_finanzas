// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import '../servicios/tema_servicio.dart';

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../modelos/movimiento_modelo.dart';
import '../modelos/deuda_modelo.dart';
import '../modelos/gasto_fijo_modelo.dart';

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/cards/balance_card.dart';
import '../componentes/cards/gastos_fijos_resumen_card.dart';
import '../componentes/cards/movimiento_item_tile.dart';
import '../componentes/modales/nuevo_movimiento_modal.dart';

// ==========================================
// PANTALLA PRINCIPAL: INICIO
// ==========================================
class InicioScreen extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final List<GastoFijoModelo> listaGastosFijos;
  final double dineroDisponible;
  final Function(MovimientoModelo) alRegistrarMovimiento;
  final VoidCallback? alPulsarNuevaMeta;
  final VoidCallback? alAbrirPanelFinanzas;
  final VoidCallback? alPulsarNuevoGastoFijo;
  final Function(GastoFijoModelo)? alMarcarGastoFijoPagado;
  final Function(GastoFijoModelo)? alEditarGastoFijo;
  final Function(GastoFijoModelo)? alEliminarGastoFijo;

  const InicioScreen({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    this.listaGastosFijos = const [],
    this.dineroDisponible = 0.0,
    required this.alRegistrarMovimiento,
    this.alPulsarNuevaMeta,
    this.alAbrirPanelFinanzas,
    this.alPulsarNuevoGastoFijo,
    this.alMarcarGastoFijoPagado,
    this.alEditarGastoFijo,
    this.alEliminarGastoFijo,
  });

  // Métodos de cálculo dinámico para el balance
  double get _totalIngresos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acumulado, m) => acumulado + m.monto);

  double get _totalGastos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (acumulado, m) => acumulado + m.monto);

  // Función para abrir el modal de nuevo movimiento
  void _mostrarModalRegistro(BuildContext context, TipoMovimiento tipoInicial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.tarjeta(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevoMovimientoModal(
        tipoInicial: tipoInicial,
        listaDeudasActivas: listaDeudas,
        dineroDisponible: dineroDisponible,
        alGuardarMovimiento: alRegistrarMovimiento,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con título, alternador de modo oscuro y botón de finanzas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'Mi Resumen Financiero',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.texto(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Botón para alternar Modo Claro / Oscuro
                      InkWell(
                        onTap: () =>
                            TemaServicio.instancia.alternarTema(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: ColoresApp.tarjeta(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ColoresApp.borde(context),
                            ),
                          ),
                          child: Icon(
                            ColoresApp.esOscuro(context)
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 18,
                            color: ColoresApp.esOscuro(context)
                                ? Colors.amber
                                : ColoresApp.texto(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (alAbrirPanelFinanzas != null)
                        InkWell(
                          onTap: alAbrirPanelFinanzas,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ColoresApp.primarioVerde.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.pie_chart_rounded,
                                  size: 18,
                                  color: ColoresApp.primarioVerde,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Gráficas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ColoresApp.primarioVerde,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Banner interactivo: Dinero Disponible Líquido
              InkWell(
                onTap: alAbrirPanelFinanzas,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: dineroDisponible >= 0
                        ? ColoresApp.primarioVerde.withValues(
                            alpha: ColoresApp.esOscuro(context) ? 0.18 : 0.08,
                          )
                        : (ColoresApp.esOscuro(context)
                              ? Colors.red.shade900.withValues(alpha: 0.3)
                              : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dineroDisponible >= 0
                          ? ColoresApp.primarioVerde.withValues(alpha: 0.3)
                          : (ColoresApp.esOscuro(context)
                                ? Colors.red.shade700
                                : Colors.red.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dineroDisponible >= 0
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: dineroDisponible >= 0
                            ? ColoresApp.primarioVerde
                            : ColoresApp.gastoRojo,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dinero disponible para gastar hoy:',
                              style: TextStyle(
                                fontSize: 11,
                                color: ColoresApp.subtexto(context),
                              ),
                            ),
                            Text(
                              '\$${dineroDisponible.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dineroDisponible >= 0
                                    ? ColoresApp.primarioVerde
                                    : ColoresApp.gastoRojo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: ColoresApp.subtexto(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta principal de balance reactivo con el disponible real
              BalanceCard(
                saldoTotal: dineroDisponible,
                ingresosMes: _totalIngresos,
                gastosMes: _totalGastos,
              ),
              const SizedBox(height: 24),

              // Botones de acciones rápidas
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.texto(context),
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
                    alPresionar: () =>
                        _mostrarModalRegistro(context, TipoMovimiento.ingreso),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.remove_rounded,
                    etiqueta: 'Gasto',
                    colorFondo: ColoresApp.gastoRojo,
                    alPresionar: () =>
                        _mostrarModalRegistro(context, TipoMovimiento.gasto),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.credit_card_rounded,
                    etiqueta: 'Tarjeta',
                    colorFondo: Colors.purple,
                    alPresionar: () =>
                        _mostrarModalRegistro(context, TipoMovimiento.gasto),
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.flag_rounded,
                    etiqueta: 'Meta',
                    colorFondo: ColoresApp.metaNaranja,
                    alPresionar: alPulsarNuevaMeta ?? () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tarjeta visual interactiva de Gastos Fijos y Suscripciones Recurrentes
              GastosFijosResumenCard(
                listaGastosFijos: listaGastosFijos,
                alPulsarNuevoGastoFijo: alPulsarNuevoGastoFijo ?? () {},
                alMarcarPagado: alMarcarGastoFijoPagado ?? (_) {},
                alEditarGastoFijo: alEditarGastoFijo ?? (_) {},
                alEliminarGastoFijo: alEliminarGastoFijo ?? (_) {},
              ),
              const SizedBox(height: 28),

              // Encabezado de movimientos recientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Movimientos Recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.texto(context),
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Ver todos')),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de movimientos recientes o estado vacío
              if (listaMovimientos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: ColoresApp.subtexto(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no hay movimientos registrados',
                        style: TextStyle(color: ColoresApp.subtexto(context)),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColoresApp.texto(context),
            ),
          ),
        ],
      ),
    );
  }
}
