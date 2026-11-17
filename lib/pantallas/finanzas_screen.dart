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
import '../modelos/deuda_modelo.dart';
import '../modelos/meta_modelo.dart';
import '../modelos/gasto_fijo_modelo.dart';

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/graficas/grafica_dona_categorias.dart';
import '../componentes/comunes/boton_modo_oscuro.dart';

// ==========================================
// PANTALLA: PANEL DE FINANZAS Y GRAFICAS
// ==========================================
class FinanzasScreen extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final List<MetaModelo> listaMetas;
  final List<GastoFijoModelo> listaGastosFijos;
  final VoidCallback? alAbrirMenuLateral;

  const FinanzasScreen({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    required this.listaMetas,
    this.listaGastosFijos = const [],
    this.alAbrirMenuLateral,
  });

  // Cálculos financieros
  double get _totalIngresos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _totalGastosGeneral => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (acum, m) => acum + m.monto);

  // Gastos pagados en efectivo / débito (salida de efectivo real)
  double get _gastosEfectivoDebito => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto && !m.pagadoConTarjeta)
      .fold(0.0, (acum, m) => acum + m.monto);

  // Ahorro apartado en metas
  double get _totalAhorradoMetas =>
      listaMetas.fold(0.0, (acum, m) => acum + m.montoAhorrado);

  // Dinero Líquido Disponible Real coherente con apartados y movimientos
  double get _dineroDisponibleReal {
    final double ahorroMovimientos = listaMovimientos
        .where((m) => m.categoria == 'Ahorro / Metas')
        .fold(0.0, (acum, m) => acum + m.monto);
    final double retiroMovimientos = listaMovimientos
        .where(
          (m) =>
              m.categoria == 'Retiro de Ahorro / Metas' ||
              m.categoria == 'Retiro de Metas',
        )
        .fold(0.0, (acum, m) => acum + m.monto);
    final double netoMovimientosMetas = ahorroMovimientos - retiroMovimientos;
    final double metasSinMovimiento =
        (_totalAhorradoMetas - netoMovimientosMetas).clamp(
          0.0,
          double.infinity,
        );

    return _totalIngresos - _gastosEfectivoDebito - metasSinMovimiento;
  }

  // Agrupación de gastos por categoría para la gráfica de dona
  List<SegmentoCategoriaDona> get _segmentosGastosPorCategoria {
    final Map<String, double> agrupados = {};
    final Map<String, IconData> iconos = {};

    final gastos = listaMovimientos.where(
      (m) => m.tipo == TipoMovimiento.gasto,
    );

    for (final g in gastos) {
      agrupados[g.categoria] = (agrupados[g.categoria] ?? 0.0) + g.monto;
      iconos[g.categoria] = g.icono;
    }

    final coloresPaleta = [
      const Color(0xFFE53935),
      const Color(0xFFFB8C00),
      const Color(0xFF8E24AA),
      const Color(0xFF1E88E5),
      const Color(0xFF00897B),
      const Color(0xFF43A047),
      const Color(0xFF3949AB),
      const Color(0xFF6D4C41),
    ];

    int indiceColor = 0;
    return agrupados.entries.map((entry) {
      final color = coloresPaleta[indiceColor % coloresPaleta.length];
      indiceColor++;
      return SegmentoCategoriaDona(
        nombre: entry.key,
        monto: entry.value,
        color: color,
        icono: iconos[entry.key] ?? Icons.category_rounded,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool saldoSaludable = _dineroDisponibleReal > 0;
    final double porcentajeComprometido = _totalIngresos > 0
        ? ((_gastosEfectivoDebito + _totalAhorradoMetas) / _totalIngresos)
              .clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      appBar: AppBar(
        title: Text(
          'Análisis Financiero & Gráficas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: ColoresApp.texto(context),
          ),
        ),
        backgroundColor: ColoresApp.fondo(context),
        elevation: 0,
        leading: alAbrirMenuLateral != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menú principal',
                onPressed: alAbrirMenuLateral,
              )
            : null,
        actions: const [
          BotonModoOscuro(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // TARJETA PRINCIPAL: DINERO DISPONIBLE REAL
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: saldoSaludable
                          ? [const Color(0xFF004D40), ColoresApp.primarioVerde]
                          : [const Color(0xFFB71C1C), const Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (saldoSaludable ? ColoresApp.primarioVerde : Colors.red)
                                .withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'DINERO DISPONIBLE HOY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  saldoSaludable
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  saldoSaludable ? 'Liquidez Libre' : 'Sobregiro',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${_dineroDisponibleReal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        saldoSaludable
                            ? 'Fondos libres en cuenta y efectivo listos para usar sin tocar tus metas.'
                            : 'Atención: Has gastado o comprometido más efectivo del que ingresaste.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),

                      // Desglose de liquidez responsivo
                      Row(
                        children: [
                          Expanded(
                            child: _ElementoDesgloseBlanco(
                              etiqueta: 'Ingresos',
                              valor: '+\$${_totalIngresos.toStringAsFixed(0)}',
                            ),
                          ),
                          Expanded(
                            child: _ElementoDesgloseBlanco(
                              etiqueta: 'Gastos Débito',
                              valor: '-\$${_gastosEfectivoDebito.toStringAsFixed(0)}',
                            ),
                          ),
                          Expanded(
                            child: _ElementoDesgloseBlanco(
                              etiqueta: 'En Metas',
                              valor: '-\$${_totalAhorradoMetas.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 16),

            // ==========================================
            // TERMOMETRO / SALUD FINANCIERA
            // ==========================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresApp.tarjeta(context),
                borderRadius: BorderRadius.circular(20),
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
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: ColoresApp.primarioVerde,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Capacidad de Gasto & Compromiso',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.texto(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(porcentajeComprometido * 100).toStringAsFixed(0)}% ocupado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: porcentajeComprometido > 0.85
                              ? ColoresApp.gastoRojo
                              : ColoresApp.primarioVerde,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: porcentajeComprometido,
                      minHeight: 10,
                      backgroundColor: ColoresApp.esOscuro(context)
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      color: porcentajeComprometido > 0.85
                          ? ColoresApp.gastoRojo
                          : (porcentajeComprometido > 0.65
                                ? Colors.amber.shade700
                                : ColoresApp.primarioVerde),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    porcentajeComprometido <= 0.65
                        ? '🟢 Excelente: Tienes más del 35% de tus ingresos disponibles para imprevistos o ahorro.'
                        : (porcentajeComprometido <= 0.85
                              ? '🟡 Precaución: Has comprometido la mayor parte de tu liquidez este mes.'
                              : '🔴 Límite crítico: Te queda muy poco margen antes de sobregirarte.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: ColoresApp.subtexto(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // GRAFICA DE DONA: GASTOS POR CATEGORIA
            // ==========================================
            GraficaDonaCategoriasCard(
              segmentos: _segmentosGastosPorCategoria,
              totalGastos: _totalGastosGeneral,
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ELEMENTO DE DESGLOSE EN BLANCO
// ==========================================
class _ElementoDesgloseBlanco extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _ElementoDesgloseBlanco({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
