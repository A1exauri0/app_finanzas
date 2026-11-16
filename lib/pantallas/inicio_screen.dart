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

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/balance_card.dart';
import '../componentes/movimiento_item_tile.dart';

// ==========================================
// PANTALLA PRINCIPAL: INICIO
// ==========================================
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de prueba simulados
    final List<MovimientoModelo> movimientosRecientes = [
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

              // Tarjeta principal de balance
              const BalanceCard(
                saldoTotal: 28450.00,
                ingresosMes: 30000.00,
                gastosMes: 6420.50,
              ),
              const SizedBox(height: 24),

              // Botones de acciones rapidas
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
                    alPresionar: () {},
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.remove_rounded,
                    etiqueta: 'Gasto',
                    colorFondo: ColoresApp.gastoRojo,
                    alPresionar: () {},
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.flag_rounded,
                    etiqueta: 'Meta',
                    colorFondo: ColoresApp.metaNaranja,
                    alPresionar: () {},
                  ),
                  _BotonAccionRapidaItem(
                    icono: Icons.trending_up_rounded,
                    etiqueta: 'Inversión',
                    colorFondo: ColoresApp.inversionAzul,
                    alPresionar: () {},
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

              // Lista de movimientos recientes
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movimientosRecientes.length,
                itemBuilder: (context, index) {
                  final movimiento = movimientosRecientes[index];
                  return MovimientoItemTile(
                    movimiento: movimiento,
                    alPulsar: () {},
                  );
                },
              ),
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
