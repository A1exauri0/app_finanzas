// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// COMPONENTE VISUAL: GRAFICA DE BARRAS COMPARATIVA
// ==========================================
class GraficaBarrasBalanceCard extends StatelessWidget {
  final double totalIngresos;
  final double totalGastos;
  final double totalAhorroMetas;

  const GraficaBarrasBalanceCard({
    super.key,
    required this.totalIngresos,
    required this.totalGastos,
    required this.totalAhorroMetas,
  });

  @override
  Widget build(BuildContext context) {
    final double maximo = math.max(
      totalIngresos,
      math.max(totalGastos, totalAhorroMetas),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la tarjeta
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: ColoresApp.primarioVerde),
              SizedBox(width: 8),
              Text(
                'Comparativa de Flujo de Dinero',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Barras visuales comparativas
          _BarraItem(
            etiqueta: 'Ingresos Totales',
            monto: totalIngresos,
            maximo: maximo,
            color: ColoresApp.ingresoVerde,
            icono: Icons.arrow_downward_rounded,
          ),
          const SizedBox(height: 14),

          _BarraItem(
            etiqueta: 'Gastos Realizados',
            monto: totalGastos,
            maximo: maximo,
            color: ColoresApp.gastoRojo,
            icono: Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: 14),

          _BarraItem(
            etiqueta: 'Ahorro Apartado en Metas',
            monto: totalAhorroMetas,
            maximo: maximo,
            color: Colors.blue.shade600,
            icono: Icons.flag_rounded,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ITEM DE BARRA INDIVIDUAL
// ==========================================
class _BarraItem extends StatelessWidget {
  final String etiqueta;
  final double monto;
  final double maximo;
  final Color color;
  final IconData icono;

  const _BarraItem({
    required this.etiqueta,
    required this.monto,
    required this.maximo,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final double fraccion = maximo > 0 ? (monto / maximo).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ColoresApp.textoPrincipal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraccion == 0 ? 0.01 : fraccion,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
