// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// COMPONENTE VISUAL: TARJETA DE BALANCE PRINCIPAL
// ==========================================
class BalanceCard extends StatelessWidget {
  final double saldoTotal;
  final double ingresosMes;
  final double gastosMes;

  const BalanceCard({
    super.key,
    required this.saldoTotal,
    required this.ingresosMes,
    required this.gastosMes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ColoresApp.primarioVerde,
            ColoresApp.secundarioVerdeClaro,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.primarioVerde.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo del saldo
          const Text(
            'Balance Disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Monto total principal
          Text(
            '\$${saldoTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Fila de resumen: Ingresos y Gastos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Columna de Ingresos
              _IndicadorFinancieroItem(
                etiquetaTexto: 'Ingresos',
                montoTexto: '+\$${ingresosMes.toStringAsFixed(2)}',
                icono: Icons.arrow_downward_rounded,
                colorIcono: Colors.greenAccent,
              ),

              // Divisor vertical sutil
              Container(
                height: 35,
                width: 1,
                color: Colors.white24,
              ),

              // Columna de Gastos
              _IndicadorFinancieroItem(
                etiquetaTexto: 'Gastos',
                montoTexto: '-\$${gastosMes.toStringAsFixed(2)}',
                icono: Icons.arrow_upward_rounded,
                colorIcono: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ITEM DE INDICADOR
// ==========================================
class _IndicadorFinancieroItem extends StatelessWidget {
  final String etiquetaTexto;
  final String montoTexto;
  final IconData icono;
  final Color colorIcono;

  const _IndicadorFinancieroItem({
    required this.etiquetaTexto,
    required this.montoTexto,
    required this.icono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white12,
          child: Icon(icono, color: colorIcono, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiquetaTexto,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              montoTexto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
