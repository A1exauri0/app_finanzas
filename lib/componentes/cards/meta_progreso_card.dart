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
import '../../modelos/meta_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: TARJETA DE PROGRESO DE META
// ==========================================
class MetaProgresoCard extends StatelessWidget {
  final MetaModelo meta;
  final Function(MetaModelo) alPulsarAbonar;
  final Function(MetaModelo) alPulsarRetirar;
  final Function(MetaModelo) alPulsarEditar;
  final Function(MetaModelo) alPulsarEliminar;

  const MetaProgresoCard({
    super.key,
    required this.meta,
    required this.alPulsarAbonar,
    required this.alPulsarRetirar,
    required this.alPulsarEditar,
    required this.alPulsarEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final double progreso = meta.porcentajeProgreso;
    final bool cumplida = meta.estaCumplida;
    final int porcentajeEntero = (progreso * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cumplida ? Colors.green.shade300 : meta.color.withValues(alpha: 0.25),
          width: cumplida ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (cumplida ? Colors.green : meta.color).withValues(
              alpha: ColoresApp.esOscuro(context) ? 0.15 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Icono, Título, Categoría y Menú de opciones (sin desbordamiento)
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: (cumplida ? Colors.green : meta.color).withValues(alpha: 0.14),
                child: Icon(
                  cumplida ? Icons.check_circle_rounded : meta.icono,
                  color: cumplida ? Colors.green.shade700 : meta.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Expanded para evitar el RenderFlex overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColoresApp.subtexto(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (cumplida)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 14, color: Colors.green.shade800),
                      const SizedBox(width: 4),
                      Text(
                        '¡Lograda!',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$porcentajeEntero%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: meta.color,
                  ),
                ),
              // Menú de opciones: Editar o Eliminar
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: ColoresApp.subtexto(context), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (valor) {
                  if (valor == 'editar') {
                    alPulsarEditar(meta);
                  } else if (valor == 'retirar') {
                    alPulsarRetirar(meta);
                  } else if (valor == 'eliminar') {
                    alPulsarEliminar(meta);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: ColoresApp.texto(context), size: 20),
                        const SizedBox(width: 10),
                        const Text('Editar Meta'),
                      ],
                    ),
                  ),
                  if (meta.montoAhorrado > 0)
                    PopupMenuItem<String>(
                      value: 'retirar',
                      child: Row(
                        children: [
                          Icon(Icons.outbox_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Text('Retirar Ahorro'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: ColoresApp.gastoRojo, size: 20),
                        SizedBox(width: 10),
                        Text('Eliminar Meta', style: TextStyle(color: ColoresApp.gastoRojo)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progreso estilizada
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 9,
              backgroundColor: ColoresApp.esOscuro(context)
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                cumplida ? Colors.green : meta.color,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fila de montos: Ahorrado vs Objetivo responsiva
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorrado',
                      style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${meta.montoAhorrado.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cumplida
                              ? Colors.green.shade400
                              : ColoresApp.texto(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        cumplida ? 'Total de Meta' : 'Faltan: \$${meta.montoFaltante.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cumplida ? Colors.green.shade400 : Colors.amber.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Objetivo: \$${meta.montoObjetivo.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColoresApp.subtexto(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Indicador de ahorro mensual sugerido o días restantes responsivo
          if (!cumplida && meta.diasRestantes != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ColoresApp.tarjetaElevada(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: ColoresApp.subtexto(context)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Quedan ${meta.diasRestantes} días',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (meta.ahorroMensualSugerido != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Ahorrar ~\$${meta.ahorroMensualSugerido!.toStringAsFixed(0)}/mes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: meta.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Botones de acción: Abonar y Retirar de forma dinámica
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => alPulsarAbonar(meta),
                  icon: Icon(
                    cumplida ? Icons.add_circle_outline_rounded : Icons.savings_rounded,
                    size: 18,
                  ),
                  label: Text(
                    cumplida ? 'Añadir más' : 'Abonar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: cumplida ? Colors.green : meta.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (meta.montoAhorrado > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => alPulsarRetirar(meta),
                    icon: const Icon(Icons.outbox_rounded, size: 18),
                    label: const Text(
                      'Retirar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.texto(context),
                      side: BorderSide(color: ColoresApp.borde(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
