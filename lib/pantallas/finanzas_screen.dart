// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import '../servicios/tema_servicio.dart';

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
import '../componentes/graficas/grafica_barras_balance.dart';

// ==========================================
// PANTALLA: PANEL DE FINANZAS Y GRAFICAS
// ==========================================
class FinanzasScreen extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final List<MetaModelo> listaMetas;
  final List<GastoFijoModelo> listaGastosFijos;

  const FinanzasScreen({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    required this.listaMetas,
    this.listaGastosFijos = const [],
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

  // Gastos pagados con tarjeta de crédito (deuda diferida)
  double get _gastosConTarjeta => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto && m.pagadoConTarjeta)
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

  // Crédito total disponible en tarjetas
  double get _creditoDisponibleTarjetas => listaDeudas
      .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
      .fold(0.0, (acum, d) => acum + d.creditoDisponible);

  // Deuda total pendiente por pagar
  double get _totalDeudaPendiente => listaDeudas
      .where((d) => d.tipoDeuda != TipoDeuda.meDeben)
      .fold(0.0, (acum, d) => acum + d.montoPendiente);

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
        actions: [
          IconButton(
            tooltip: 'Alternar Modo Oscuro',
            icon: Icon(
              ColoresApp.esOscuro(context)
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: ColoresApp.esOscuro(context)
                  ? Colors.amber
                  : ColoresApp.texto(context),
            ),
            onPressed: () => TemaServicio.instancia.alternarTema(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  Text(
                    '\$${_dineroDisponibleReal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
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

                  // Desglose de liquidez
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ElementoDesgloseBlanco(
                        etiqueta: 'Ingresos',
                        valor: '+\$${_totalIngresos.toStringAsFixed(0)}',
                      ),
                      _ElementoDesgloseBlanco(
                        etiqueta: 'Gastos Débito',
                        valor: '-\$${_gastosEfectivoDebito.toStringAsFixed(0)}',
                      ),
                      _ElementoDesgloseBlanco(
                        etiqueta: 'En Metas',
                        valor: '-\$${_totalAhorradoMetas.toStringAsFixed(0)}',
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
            // TARJETAS DE CREDITO VS DEUDA TOTAL
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColoresApp.esOscuro(context)
                          ? Colors.purple.shade900.withValues(alpha: 0.3)
                          : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ColoresApp.esOscuro(context)
                            ? Colors.purple.shade700
                            : Colors.purple.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              color: ColoresApp.esOscuro(context)
                                  ? Colors.purple.shade300
                                  : Colors.purple,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Crédito Libre',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColoresApp.esOscuro(context)
                                    ? Colors.purple.shade300
                                    : Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_creditoDisponibleTarjetas.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.esOscuro(context)
                                ? Colors.purple.shade200
                                : Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Disponible en tarjetas',
                          style: TextStyle(
                            fontSize: 11,
                            color: ColoresApp.subtexto(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColoresApp.esOscuro(context)
                          ? Colors.orange.shade900.withValues(alpha: 0.3)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ColoresApp.esOscuro(context)
                            ? Colors.orange.shade700
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_rounded,
                              color: ColoresApp.esOscuro(context)
                                  ? Colors.orange.shade300
                                  : Colors.deepOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Deuda Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColoresApp.esOscuro(context)
                                    ? Colors.orange.shade300
                                    : Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_totalDeudaPendiente.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.esOscuro(context)
                                ? Colors.orange.shade200
                                : Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tarjetas y préstamos',
                          style: TextStyle(
                            fontSize: 11,
                            color: ColoresApp.subtexto(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ==========================================
            // GRAFICA DE DONA: GASTOS POR CATEGORIA
            // ==========================================
            GraficaDonaCategoriasCard(
              segmentos: _segmentosGastosPorCategoria,
              totalGastos: _totalGastosGeneral,
            ),
            const SizedBox(height: 16),

            // ==========================================
            // GRAFICA DE BARRAS: COMPARATIVA DE FLUJO
            // ==========================================
            GraficaBarrasBalanceCard(
              totalIngresos: _totalIngresos,
              totalGastos: _totalGastosGeneral,
              totalAhorroMetas: _totalAhorradoMetas,
            ),
            const SizedBox(height: 16),

            // ==========================================
            // CONSEJOS Y DIAGNOSTICO INTELIGENTE
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
                      const Icon(Icons.lightbulb_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Recomendaciones del Asesor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.texto(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ItemConsejo(
                    texto: _gastosConTarjeta > 0
                        ? 'Has gastado \$${_gastosConTarjeta.toStringAsFixed(2)} a crédito. Recuerda apartar ese dinero antes de tu fecha límite para evitar intereses.'
                        : 'No tienes cargos pendientes de tarjeta generados recientemente.',
                  ),
                  const SizedBox(height: 8),
                  _ItemConsejo(
                    texto: _dineroDisponibleReal < 1000
                        ? 'Tu reserva líquida es menor a \$1,000. Prioriza frenar gastos no esenciales hasta tu próximo ingreso.'
                        : 'Tu fondo disponible está en buen nivel. Considera destinar un porcentaje extra a tus metas de ahorro.',
                  ),
                ],
              ),
            ),
          ],
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
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ITEM DE CONSEJO
// ==========================================
class _ItemConsejo extends StatelessWidget {
  final String texto;

  const _ItemConsejo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: ColoresApp.primarioVerde,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 13, color: ColoresApp.texto(context)),
          ),
        ),
      ],
    );
  }
}
