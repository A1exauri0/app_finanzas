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
import '../componentes/cards/balance_card.dart';
import '../componentes/cards/movimiento_item_tile.dart';
import '../componentes/graficas/grafica_dona_categorias.dart';
import '../componentes/comunes/boton_modo_oscuro.dart';

// ==========================================
// PANTALLA PRINCIPAL: INICIO CON GRAFICAS & RESUMEN
// ==========================================
class InicioScreen extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final List<MetaModelo> listaMetas;
  final List<GastoFijoModelo> listaGastosFijos;
  final double dineroDisponible;
  final Function(MovimientoModelo)? alRegistrarMovimiento;
  final VoidCallback? alPulsarNuevaMeta;
  final VoidCallback? alAbrirMenuLateral;
  final VoidCallback? alPulsarVerTodosMovimientos;

  const InicioScreen({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    this.listaMetas = const [],
    this.listaGastosFijos = const [],
    this.dineroDisponible = 0.0,
    this.alRegistrarMovimiento,
    this.alPulsarNuevaMeta,
    this.alAbrirMenuLateral,
    this.alPulsarVerTodosMovimientos,
  });

  // ==========================================
  // METODOS DE CALCULO FINANCIERO Y GRAFICAS
  // ==========================================
  double get _totalIngresos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _totalGastosGeneral => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _gastosEfectivoDebito => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.gasto && !m.pagadoConTarjeta)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _totalAhorradoMetas => listaMetas.fold(
    0.0,
    (acum, meta) => acum + meta.montoAhorrado,
  );

  // Segmentos para la gráfica de dona interactiva
  List<SegmentoCategoriaDona> get _segmentosGastosPorCategoria {
    final gastos = listaMovimientos.where((m) => m.tipo == TipoMovimiento.gasto);
    final Map<String, double> agrupados = {};
    final Map<String, IconData> iconos = {};

    for (final m in gastos) {
      agrupados[m.categoria] = (agrupados[m.categoria] ?? 0.0) + m.monto;
      iconos[m.categoria] = m.icono;
    }

    final coloresPaleta = [
      ColoresApp.primarioVerde,
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
    final double porcentajeComprometido = _totalIngresos > 0
        ? ((_gastosEfectivoDebito + _totalAhorradoMetas) / _totalIngresos)
            .clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      appBar: AppBar(
        title: Text(
          'Mi Resumen Financiero',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: ColoresApp.texto(context),
          ),
        ),
        backgroundColor: ColoresApp.fondo(context),
        elevation: 0,
        centerTitle: false,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // SECCION 1: GRAFICA DE DONA DE DISTRIBUCION DE GASTOS
            // ==========================================
            GraficaDonaCategoriasCard(
              segmentos: _segmentosGastosPorCategoria,
              totalGastos: _totalGastosGeneral,
            ),
            const SizedBox(height: 16),

            // ==========================================
            // SECCION 2: BALANCE DISPONIBLE & LIQUIDEZ
            // ==========================================
            BalanceCard(
              saldoTotal: dineroDisponible,
              ingresosMes: _totalIngresos,
              gastosMes: _totalGastosGeneral,
            ),
            const SizedBox(height: 16),

            // ==========================================
            // SECCION 3: CAPACIDAD DE GASTO & COMPROMISO
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.texto(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${(porcentajeComprometido * 100).toStringAsFixed(0)}% ocupado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: porcentajeComprometido > 0.85
                                ? ColoresApp.gastoRojo
                                : ColoresApp.primarioVerde,
                          ),
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
                        ? '🟢 Excelente: Tienes más del 35% de tus ingresos libres para imprevistos o ahorro.'
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
            // SECCION 4: ULTIMOS MOVIMIENTOS RECIENTES
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Movimientos Recientes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.texto(context),
                    ),
                  ),
                ),
                if (alPulsarVerTodosMovimientos != null)
                  TextButton(
                    onPressed: alPulsarVerTodosMovimientos,
                    child: const Text('Ver todos'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de movimientos recientes o estado vacío
            if (listaMovimientos.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: ColoresApp.subtexto(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aún no hay movimientos registrados',
                      style: TextStyle(color: ColoresApp.subtexto(context)),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listaMovimientos.length > 5 ? 5 : listaMovimientos.length,
                itemBuilder: (context, index) {
                  final movimiento = listaMovimientos[index];
                  return MovimientoItemTile(
                    movimiento: movimiento,
                    alPulsar: () {},
                  );
                },
              ),

            // Espacio inferior para no tapar con el botón flotante y bottom app bar
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
