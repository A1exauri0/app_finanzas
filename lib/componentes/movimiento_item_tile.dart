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
// COMPONENTE VISUAL: TILE DE MOVIMIENTO
// ==========================================
class MovimientoItemTile extends StatelessWidget {
  final MovimientoModelo movimiento;
  final VoidCallback? alPulsar;

  const MovimientoItemTile({
    super.key,
    required this.movimiento,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    final Color colorMonto = esIngreso ? ColoresApp.ingresoVerde : ColoresApp.gastoRojo;
    final String prefijoMonto = esIngreso ? '+' : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: ColoresApp.esOscuro(context) ? 0.2 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: alPulsar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: colorMonto.withValues(alpha: 0.12),
          child: Icon(movimiento.icono, color: colorMonto, size: 22),
        ),
        title: Text(
          movimiento.titulo,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: ColoresApp.texto(context),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              movimiento.categoria,
              style: TextStyle(
                fontSize: 13,
                color: ColoresApp.subtexto(context),
              ),
            ),
            if (movimiento.pagadoConTarjeta &&
                movimiento.nombreTarjetaUtilizada != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColoresApp.esOscuro(context)
                      ? Colors.purple.shade900.withValues(alpha: 0.4)
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 12,
                      color: ColoresApp.esOscuro(context)
                          ? Colors.purple.shade200
                          : Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movimiento.nombreTarjetaUtilizada!,
                      style: TextStyle(
                        fontSize: 11,
                        color: ColoresApp.esOscuro(context)
                            ? Colors.purple.shade200
                            : Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '$prefijoMonto\$${movimiento.monto.toStringAsFixed(2)}',
          style: TextStyle(
            color: colorMonto,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
