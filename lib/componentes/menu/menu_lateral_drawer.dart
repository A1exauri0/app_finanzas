// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import '../../servicios/tema_servicio.dart';

// ==========================================
// COMPONENTE VISUAL: MENU LATERAL (DRAWER)
// ==========================================
class MenuLateralDrawer extends StatelessWidget {
  final double? dineroDisponible;
  final int indicePestanaActual;
  final Function(int) alSeleccionarPestana;
  final VoidCallback? alAbrirPanelFinanzas;
  final VoidCallback alRegistrarMovimiento;

  const MenuLateralDrawer({
    super.key,
    this.dineroDisponible,
    required this.indicePestanaActual,
    required this.alSeleccionarPestana,
    this.alAbrirPanelFinanzas,
    required this.alRegistrarMovimiento,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ColoresApp.tarjeta(context),
      child: Column(
        children: [
          // ==========================================
          // ENCABEZADO MINIMALISTA DE LA APLICACION
          // ==========================================
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16, left: 20, right: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColoresApp.primarioVerde.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: ColoresApp.primarioVerde,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Finanzas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.texto(context),
                          ),
                        ),
                        Text(
                          'Control & Finanzas Personales',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColoresApp.subtexto(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ==========================================
          // OPCIONES DE NAVEGACION PRINCIPAL
          // ==========================================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _ItemMenuLateral(
                  icono: Icons.home_rounded,
                  titulo: 'Inicio & Gráficas',
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
                const Divider(),

                // Selector rápido interactivo de Modo Oscuro
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: TemaServicio.instancia.temaModoNotifier,
                  builder: (context, modo, _) {
                    final bool esOscuro =
                        TemaServicio.instancia.esModoOscuroActivo(context);
                    return SwitchListTile(
                      secondary: Icon(
                        esOscuro
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color:
                            esOscuro ? Colors.amber : ColoresApp.primarioVerde,
                      ),
                      title: Text(
                        'Modo Oscuro',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ColoresApp.texto(context),
                        ),
                      ),
                      subtitle: Text(
                        esOscuro ? 'Activado' : 'Desactivado',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColoresApp.subtexto(context),
                        ),
                      ),
                      value: esOscuro,
                      onChanged: (_) {
                        TemaServicio.instancia.alternarTema(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // BOTON RAPIDO INFERIOR PARA REGISTRO
          // ==========================================
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
        color: estaSeleccionado ? ColoresApp.primarioVerde : ColoresApp.subtexto(context),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.w500,
          color: estaSeleccionado ? ColoresApp.primarioVerde : ColoresApp.texto(context),
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: estaSeleccionado,
      selectedTileColor: ColoresApp.primarioVerde.withValues(
        alpha: ColoresApp.esOscuro(context) ? 0.16 : 0.08,
      ),
      onTap: alPulsar,
    );
  }
}
