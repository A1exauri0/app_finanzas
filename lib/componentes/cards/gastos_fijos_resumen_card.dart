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
import '../../modelos/gasto_fijo_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: TARJETA DE GASTOS FIJOS Y SUSCRIPCIONES
// ==========================================
class GastosFijosResumenCard extends StatelessWidget {
  final List<GastoFijoModelo> listaGastosFijos;
  final VoidCallback alPulsarNuevoGastoFijo;
  final Function(GastoFijoModelo) alMarcarPagado;
  final Function(GastoFijoModelo) alEditarGastoFijo;
  final Function(GastoFijoModelo) alEliminarGastoFijo;

  const GastosFijosResumenCard({
    super.key,
    required this.listaGastosFijos,
    required this.alPulsarNuevoGastoFijo,
    required this.alMarcarPagado,
    required this.alEditarGastoFijo,
    required this.alEliminarGastoFijo,
  });

  double get _totalComprometido => listaGastosFijos.fold(0.0, (acum, g) => acum + g.monto);
  double get _totalPagado => listaGastosFijos
      .where((g) => g.estaPagadoEsteMes)
      .fold(0.0, (acum, g) => acum + g.monto);
  double get _totalPendiente => _totalComprometido - _totalPagado;
  int get _pendientesCount => listaGastosFijos.where((g) => !g.estaPagadoEsteMes).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ColoresApp.borde(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: ColoresApp.esOscuro(context) ? 0.25 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de encabezado responsiva: Título y botón para agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: const Icon(Icons.repeat_rounded, size: 18, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gastos Fijos del Mes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColoresApp.texto(context),
                            ),
                          ),
                          Text(
                            _pendientesCount > 0
                                ? '$_pendientesCount pendientes por pagar'
                                : (listaGastosFijos.isEmpty ? 'Sin gastos registrados' : '¡Todo pagado este mes!'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: _pendientesCount > 0
                                  ? Colors.orange.shade700
                                  : ColoresApp.primarioVerde,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: alPulsarNuevoGastoFijo,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColoresApp.primarioVerde.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: ColoresApp.primarioVerde),
                      SizedBox(width: 4),
                      Text(
                        'Agregar',
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

          if (listaGastosFijos.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Resumen de montos: Comprometido vs Pagado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ColoresApp.tarjetaElevada(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _IndicadorMontoGastoFijo(
                      titulo: 'Comprometido',
                      monto: _totalComprometido,
                      color: ColoresApp.texto(context),
                    ),
                  ),
                  Container(height: 24, width: 1, color: ColoresApp.borde(context)),
                  Expanded(
                    child: _IndicadorMontoGastoFijo(
                      titulo: 'Pagado',
                      monto: _totalPagado,
                      color: ColoresApp.primarioVerde,
                    ),
                  ),
                  Container(height: 24, width: 1, color: ColoresApp.borde(context)),
                  Expanded(
                    child: _IndicadorMontoGastoFijo(
                      titulo: 'Pendiente',
                      monto: _totalPendiente,
                      color: _totalPendiente > 0 ? Colors.orange.shade700 : ColoresApp.subtexto(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lista de elementos de gastos fijos
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listaGastosFijos.length,
              separatorBuilder: (context, index) => Divider(
                height: 14,
                color: ColoresApp.borde(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final gasto = listaGastosFijos[index];
                final bool pagado = gasto.estaPagadoEsteMes;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: gasto.color.withValues(alpha: 0.15),
                      child: Icon(gasto.icono, size: 18, color: gasto.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gasto.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ColoresApp.texto(context),
                              decoration: pagado ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Día ${gasto.diaPago} • ${gasto.pagarConTarjeta ? (gasto.nombreTarjeta ?? "Tarjeta") : "Efectivo"}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColoresApp.subtexto(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Monto
                    Text(
                      '\$${gasto.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: pagado ? ColoresApp.subtexto(context) : ColoresApp.texto(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón de acción: Marcar como pagado o Check verde
                    if (pagado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: ColoresApp.primarioVerde),
                            SizedBox(width: 4),
                            Text(
                              'Listo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.primarioVerde,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () => alMarcarPagado(gasto),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColoresApp.primarioVerde,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Pagar',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Menú de opciones: Editar o Eliminar
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: ColoresApp.subtexto(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) {
                        if (val == 'editar') {
                          alEditarGastoFijo(gasto);
                        } else if (val == 'eliminar') {
                          alEliminarGastoFijo(gasto);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: ColoresApp.gastoRojo),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: ColoresApp.gastoRojo)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Registra tus suscripciones (Spotify, Meli+, etc.) o gastos mensuales para no olvidarlos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: INDICADOR DE MONTO
// ==========================================
class _IndicadorMontoGastoFijo extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;

  const _IndicadorMontoGastoFijo({
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(fontSize: 10, color: ColoresApp.subtexto(context)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$${monto.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
