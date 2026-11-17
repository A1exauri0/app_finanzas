// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../../modelos/movimiento_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: MODAL DE DETALLE DE MOVIMIENTO
// ==========================================
class DetalleMovimientoModal extends StatelessWidget {
  final MovimientoModelo movimiento;
  final VoidCallback alPulsarEditar;
  final VoidCallback alPulsarEliminar;

  const DetalleMovimientoModal({
    super.key,
    required this.movimiento,
    required this.alPulsarEditar,
    required this.alPulsarEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    final Color colorMonto = esIngreso ? ColoresApp.ingresoVerde : ColoresApp.gastoRojo;
    final String prefijoMonto = esIngreso ? '+' : '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: ColoresApp.tarjeta(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con título y botón de cierre 'X'
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalle del Movimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar ventana',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Icono y Monto Principal
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorMonto.withValues(alpha: 0.12),
                      child: Icon(movimiento.icono, size: 32, color: colorMonto),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$prefijoMonto\$${movimiento.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorMonto,
                        ),
                      ),
                    ),
                const SizedBox(height: 4),
                Text(
                  movimiento.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.textoPrincipal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Fila 1: Categoría
          _DetalleFila(
            icono: Icons.category_outlined,
            etiqueta: 'Categoría',
            valor: movimiento.categoria,
          ),
          const SizedBox(height: 14),

          // Fila 2: Fecha
          _DetalleFila(
            icono: Icons.calendar_today_rounded,
            etiqueta: 'Fecha de Registro',
            valor:
                '${movimiento.fecha.day.toString().padLeft(2, '0')}/${movimiento.fecha.month.toString().padLeft(2, '0')}/${movimiento.fecha.year}',
          ),
          const SizedBox(height: 14),

          // Fila 3: Método de Pago o Tarjeta
          if (movimiento.pagadoConTarjeta && movimiento.nombreTarjetaUtilizada != null) ...[
            _DetalleFila(
              icono: Icons.credit_card_rounded,
              etiqueta: 'Método de Pago',
              valor: 'Tarjeta: ${movimiento.nombreTarjetaUtilizada}',
              colorValor: Colors.purple.shade700,
            ),
            const SizedBox(height: 14),
          ] else if (movimiento.nombreDeudorAsociado != null) ...[
            _DetalleFila(
              icono: Icons.people_outline_rounded,
              etiqueta: esIngreso ? 'Cobrado a' : 'Abonado a',
              valor: movimiento.nombreDeudorAsociado!,
              colorValor: ColoresApp.primarioVerde,
            ),
            const SizedBox(height: 14),
          ] else ...[
            const _DetalleFila(
              icono: Icons.account_balance_wallet_outlined,
              etiqueta: 'Método de Pago',
              valor: 'Efectivo / Cuenta bancaria',
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 16),

          // Botones de acción: Editar y Eliminar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: alPulsarEditar,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: alPulsarEliminar,
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.gastoRojo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  ),
);
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: FILA DE INFORMACION
// ==========================================
class _DetalleFila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;

  const _DetalleFila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 20, color: ColoresApp.textoSecundario),
        const SizedBox(width: 12),
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 14,
            color: ColoresApp.textoSecundario,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorValor ?? ColoresApp.textoPrincipal,
            ),
          ),
        ),
      ],
    );
  }
}
