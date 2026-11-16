// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// COMPONENTE VISUAL: MENU LATERAL (DRAWER)
// ==========================================
class MenuLateralDrawer extends StatelessWidget {
  final double dineroDisponible;
  final int indicePestanaActual;
  final Function(int) alSeleccionarPestana;
  final VoidCallback alAbrirPanelFinanzas;
  final VoidCallback alRegistrarMovimiento;

  const MenuLateralDrawer({
    super.key,
    required this.dineroDisponible,
    required this.indicePestanaActual,
    required this.alSeleccionarPestana,
    required this.alAbrirPanelFinanzas,
    required this.alRegistrarMovimiento,
  });

  @override
  Widget build(BuildContext context) {
    final bool saldoPositivo = dineroDisponible > 0;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Encabezado del menú
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: saldoPositivo
                    ? [const Color(0xFF004D40), ColoresApp.primarioVerde]
                    : [const Color(0xFFB71C1C), ColoresApp.gastoRojo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.wallet_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dinero Disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${dineroDisponible.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  saldoPositivo ? '✓ Liquidez disponible libre' : '⚠️ Fondos agotados / sobregiro',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          // Elemento Destacado: Panel Financiero y Gráficas
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ColoresApp.primarioVerde.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColoresApp.primarioVerde.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: ColoresApp.primarioVerde,
                radius: 18,
                child: Icon(Icons.pie_chart_rounded, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Panel Financiero & Gráficas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
              subtitle: const Text(
                'Gráficas de dona, barras y salud',
                style: TextStyle(fontSize: 11, color: ColoresApp.textoSecundario),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: ColoresApp.primarioVerde),
              onTap: () {
                Navigator.pop(context);
                alAbrirPanelFinanzas();
              },
            ),
          ),

          const Divider(height: 1),

          // Opciones de navegación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _ItemMenuLateral(
                  icono: Icons.home_rounded,
                  titulo: 'Inicio & Resumen',
                  estaSeleccionado: indicePestanaActual == 0,
                  alPulsar: () {
                    Navigator.pop(context);
                    alSeleccionarPestana(0);
                  },
                ),
                _ItemMenuLateral(
                  icono: Icons.receipt_long_rounded,
                  titulo: 'Movimientos (Historial)',
                  estaSeleccionado: indicePestanaActual == 1,
                  alPulsar: () {
                    Navigator.pop(context);
                    alSeleccionarPestana(1);
                  },
                ),
                _ItemMenuLateral(
                  icono: Icons.flag_rounded,
                  titulo: 'Objetivos de Compra (Metas)',
                  estaSeleccionado: indicePestanaActual == 2,
                  alPulsar: () {
                    Navigator.pop(context);
                    alSeleccionarPestana(2);
                  },
                ),
                _ItemMenuLateral(
                  icono: Icons.credit_card_rounded,
                  titulo: 'Deudas & Tarjetas',
                  estaSeleccionado: indicePestanaActual == 3,
                  alPulsar: () {
                    Navigator.pop(context);
                    alSeleccionarPestana(3);
                  },
                ),
              ],
            ),
          ),

          // Botón inferior para registro rápido
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                alRegistrarMovimiento();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo Movimiento'),
              style: FilledButton.styleFrom(
                backgroundColor: ColoresApp.primarioVerde,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ITEM DE MENU LATERAL
// ==========================================
class _ItemMenuLateral extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final bool estaSeleccionado;
  final VoidCallback alPulsar;

  const _ItemMenuLateral({
    required this.icono,
    required this.titulo,
    required this.estaSeleccionado,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icono,
        color: estaSeleccionado ? ColoresApp.primarioVerde : ColoresApp.textoSecundario,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.w500,
          color: estaSeleccionado ? ColoresApp.primarioVerde : ColoresApp.textoPrincipal,
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: estaSeleccionado,
      selectedTileColor: ColoresApp.primarioVerde.withValues(alpha: 0.08),
      onTap: alPulsar,
    );
  }
}
