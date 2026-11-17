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
import '../modelos/deuda_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: TARJETA DE CUENTAS POR COBRAR
// ==========================================
class DeudasResumenCard extends StatelessWidget {
  final List<DeudaModelo> listaDeudas;
  final VoidCallback? alPulsarVerDetalles;

  const DeudasResumenCard({
    super.key,
    required this.listaDeudas,
    this.alPulsarVerDetalles,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos el total pendiente por cobrar
    final double totalPendiente = listaDeudas
        .where((d) => !d.estaSaldada)
        .fold(0.0, (acumulado, d) => acumulado + d.montoPendiente);

    final int deudoresActivos = listaDeudas.where((d) => !d.estaSaldada).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.borde(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: ColoresApp.esOscuro(context) ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ColoresApp.inversionAzul.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: ColoresApp.inversionAzul,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Dinero por Cobrar (Deudas)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.texto(context),
                    ),
                  ),
                ],
              ),
              if (alPulsarVerDetalles != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onPressed: alPulsarVerDetalles,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendiente de pago',
                    style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${totalPendiente.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.inversionAzul,
                    ),
                  ),
                ],
              ),
              Text(
                '$deudoresActivos ${deudoresActivos == 1 ? "persona debe" : "personas deben"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ColoresApp.subtexto(context),
                ),
              ),
            ],
          ),
          if (listaDeudas.isNotEmpty) ...[
            const Divider(height: 24),
            // Muestra los deudores más destacados
            ...listaDeudas.where((d) => !d.estaSaldada).take(2).map((deuda) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deuda.nombreDeudor,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                    Text(
                      'Falta: \$${deuda.montoPendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
