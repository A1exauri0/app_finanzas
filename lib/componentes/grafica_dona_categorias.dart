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
// MODELO AUXILIAR: SEGMENTO DE GRAFICA DE DONA
// ==========================================
class SegmentoCategoriaDona {
  final String nombre;
  final double monto;
  final Color color;
  final IconData icono;

  SegmentoCategoriaDona({
    required this.nombre,
    required this.monto,
    required this.color,
    required this.icono,
  });
}

// ==========================================
// COMPONENTE VISUAL: GRAFICA DE DONA DE CATEGORIAS
// ==========================================
class GraficaDonaCategoriasCard extends StatelessWidget {
  final List<SegmentoCategoriaDona> segmentos;
  final double totalGastos;

  const GraficaDonaCategoriasCard({
    super.key,
    required this.segmentos,
    required this.totalGastos,
  });

  @override
  Widget build(BuildContext context) {
    if (segmentos.isEmpty || totalGastos <= 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColoresApp.tarjeta(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No hay gastos registrados para graficar.',
            style: TextStyle(color: ColoresApp.subtexto(context)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: ColoresApp.esOscuro(context) ? 0.2 : 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la tarjeta
          Row(
            children: [
              const Icon(Icons.donut_large_rounded, color: ColoresApp.primarioVerde),
              const SizedBox(width: 8),
              Text(
                'Distribución de Gastos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.texto(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfica de dona con valor central
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _PintorDonaCategorias(
                      segmentos: segmentos,
                      total: totalGastos,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Gastos',
                        style: TextStyle(
                          fontSize: 11,
                          color: ColoresApp.subtexto(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${totalGastos.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.gastoRojo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Leyenda de categorías con porcentajes
          Column(
            children: segmentos.map((seg) {
              final double porcentaje = (seg.monto / totalGastos) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: seg.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        seg.nombre,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ColoresApp.texto(context),
                        ),
                      ),
                    ),
                    Text(
                      '${porcentaje.toStringAsFixed(1)}% ',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColoresApp.subtexto(context),
                      ),
                    ),
                    Text(
                      '\$${seg.monto.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PINTOR PERSONALIZADO: DIBUJO DE LA DONA
// ==========================================
class _PintorDonaCategorias extends CustomPainter {
  final List<SegmentoCategoriaDona> segmentos;
  final double total;

  _PintorDonaCategorias({
    required this.segmentos,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (size.width / 2) - 10;
    const grosor = 18.0;

    double anguloInicio = -math.pi / 2; // Comenzar en la parte superior (12 en punto)

    for (final seg in segmentos) {
      final proporcion = seg.monto / total;
      final anguloBarrido = proporcion * 2 * math.pi;

      final pincel = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round;

      // Dejamos un margen minúsculo entre segmentos si hay más de 1
      final double anguloSeparacion = segmentos.length > 1 ? 0.04 : 0.0;
      final double anguloEfectivo = math.max(0.01, anguloBarrido - anguloSeparacion);

      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        anguloInicio + (anguloSeparacion / 2),
        anguloEfectivo,
        false,
        pincel,
      );

      anguloInicio += anguloBarrido;
    }
  }

  @override
  bool shouldRepaint(covariant _PintorDonaCategorias oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segmentos != segmentos;
  }
}
