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
import '../../modelos/deuda_modelo.dart';
import '../../modelos/meta_modelo.dart';
import '../../modelos/gasto_fijo_modelo.dart';

// ==========================================
// COMPONENTE: TARJETA DE DISTRIBUCION DE GASTOS 50 / 20 / 30
// ==========================================
class DistribucionPresupuestoCard extends StatelessWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final List<MetaModelo> listaMetas;
  final List<GastoFijoModelo> listaGastosFijos;
  final VoidCallback? alPulsarRegistrarIngreso;

  const DistribucionPresupuestoCard({
    super.key,
    required this.listaMovimientos,
    required this.listaDeudas,
    required this.listaMetas,
    this.listaGastosFijos = const [],
    this.alPulsarRegistrarIngreso,
  });

  // ==========================================
  // METODOS AUXILIARES DE CLASIFICACION Y CALCULO
  // ==========================================
  double get _totalIngresos => listaMovimientos
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acum, m) => acum + m.monto);

  bool _esMovimientoDeuda(MovimientoModelo m) {
    if (m.tipo != TipoMovimiento.gasto) return false;
    final cat = m.categoria.toLowerCase();
    final tit = m.titulo.toLowerCase();
    return m.idDeudaAsociada != null ||
        cat.contains('deuda') ||
        cat.contains('tarjeta') ||
        tit.startsWith('pago fijo:') ||
        tit.startsWith('pago a tarjeta') ||
        tit.startsWith('pago a ');
  }

  bool _esMovimientoAhorro(MovimientoModelo m) {
    final cat = m.categoria.toLowerCase();
    final tit = m.titulo.toLowerCase();
    return cat.contains('ahorro') ||
        cat.contains('meta') ||
        tit.startsWith('ahorro para');
  }

  // ==========================================
  // CONSTRUCCION VISUAL PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final double ingresos = _totalIngresos;

    // Si aún no hay ingresos registrados en el periodo
    if (ingresos <= 0) {
      return _buildEstadoSinIngresos(context);
    }

    // 1. BOLSA DE DEUDAS (50% maximo)
    final double cupoDeudas = ingresos * 0.50;
    final double deudasPagadasMovimientos = listaMovimientos
        .where((m) => _esMovimientoDeuda(m))
        .fold(0.0, (acum, m) => acum + m.monto);
    final double compromisosPendientes = listaDeudas
            .where((d) =>
                (d.tipoDeuda == TipoDeuda.debo ||
                    d.tipoDeuda == TipoDeuda.tarjetaCredito) &&
                !d.estaSaldada)
            .fold(0.0, (acum, d) => acum + d.montoPendiente) +
        listaGastosFijos
            .where((g) => !g.estaPagadoEsteMes)
            .fold(0.0, (acum, g) => acum + g.monto);

    final double consumoDeudasTotal =
        deudasPagadasMovimientos + compromisosPendientes;

    // Regla de excedente: si sobra de deudas, pasa a ahorro
    final double sobranteDeudas = (cupoDeudas - consumoDeudasTotal).clamp(
      0.0,
      cupoDeudas,
    );
    final bool haySobranteDeudas = sobranteDeudas > 0;
    final bool excedeDeudas = consumoDeudasTotal > cupoDeudas;

    // 2. BOLSA DE AHORRO (20% base + sobrante de deudas)
    final double cupoAhorroBase = ingresos * 0.20;
    final double cupoAhorroEfectivo = cupoAhorroBase + sobranteDeudas;
    final double porcentajeAhorroEfectivo =
        (cupoAhorroEfectivo / ingresos) * 100;

    final double ahorroRealAcumulado = listaMetas.fold(
      0.0,
      (acum, meta) => acum + meta.montoAhorrado,
    );

    // 3. BOLSA DE GUSTOS (30% fijo)
    final double cupoGustos = ingresos * 0.30;
    final double gastadoGustos = listaMovimientos
        .where((m) =>
            m.tipo == TipoMovimiento.gasto &&
            !_esMovimientoDeuda(m) &&
            !_esMovimientoAhorro(m))
        .fold(0.0, (acum, m) => acum + m.monto);
    final double disponibleGustos = cupoGustos - gastadoGustos;

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
              alpha: ColoresApp.esOscuro(context) ? 0.22 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con título e icono informativo
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ColoresApp.primarioVerde.withValues(alpha: 0.14),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: ColoresApp.primarioVerde,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuesto 50 / 20 / 30',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                    Text(
                      'Distribución con traspaso a Ahorro',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColoresApp.subtexto(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: ColoresApp.subtexto(context),
                  size: 20,
                ),
                tooltip: '¿Cómo funciona esta división?',
                onPressed: () => _mostrarModalExplicativo(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner dinámico de excedente o alerta de deudas
          if (haySobranteDeudas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(
                  alpha: ColoresApp.esOscuro(context) ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Excelente! Te sobraron \$${sobranteDeudas.toStringAsFixed(2)} de deudas y se transfirieron automáticamente a tu bolsa de Ahorro.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.esOscuro(context)
                            ? Colors.tealAccent.shade100
                            : Colors.teal.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (excedeDeudas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(
                  alpha: ColoresApp.esOscuro(context) ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tus deudas superan el 50% recomendado (+\$${(consumoDeudasTotal - cupoDeudas).toStringAsFixed(2)}). Intenta limitar los gustos para no desbalancearte.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.esOscuro(context)
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ==========================================
          // BARRA 1: DEUDAS Y OBLIGACIONES (50%)
          // ==========================================
          _ItemPresupuestoBarra(
            titulo: 'Deudas & Obligaciones',
            etiquetaPorcentaje: '50% máx',
            montoConsumido: consumoDeudasTotal,
            montoCupo: cupoDeudas,
            colorBarra: const Color(0xFF5C6BC0), // Azul Índigo
            icono: Icons.credit_card_rounded,
            mensajePie: haySobranteDeudas
                ? 'Sobrante: \$${sobranteDeudas.toStringAsFixed(2)} ➔ reorientado a Ahorro'
                : (excedeDeudas
                    ? 'Excedido por \$${(consumoDeudasTotal - cupoDeudas).toStringAsFixed(2)}'
                    : 'Dentro del cupo asignado'),
            esSobrantePositivo: haySobranteDeudas,
          ),
          const SizedBox(height: 14),

          // ==========================================
          // BARRA 2: AHORRO Y METAS (20% + SOBRANTE)
          // ==========================================
          _ItemPresupuestoBarra(
            titulo: 'Ahorro & Metas',
            etiquetaPorcentaje: haySobranteDeudas
                ? '${porcentajeAhorroEfectivo.toStringAsFixed(0)}% (20% + bono)'
                : '20% base',
            montoConsumido: ahorroRealAcumulado,
            montoCupo: cupoAhorroEfectivo,
            colorBarra: ColoresApp.primarioVerde, // Verde Esmeralda
            icono: Icons.savings_rounded,
            mensajePie: haySobranteDeudas
                ? '¡Capacidad de ahorro ampliada con el remanente de deudas!'
                : 'Meta mensual base: \$${cupoAhorroBase.toStringAsFixed(2)}',
            esSobrantePositivo: true,
          ),
          const SizedBox(height: 14),

          // ==========================================
          // BARRA 3: GUSTOS Y DIARIOS (30%)
          // ==========================================
          _ItemPresupuestoBarra(
            titulo: 'Gustos & Estilo de Vida',
            etiquetaPorcentaje: '30% libre',
            montoConsumido: gastadoGustos,
            montoCupo: cupoGustos,
            colorBarra: const Color(0xFFFB8C00), // Naranja / Ámbar
            icono: Icons.shopping_bag_outlined,
            mensajePie: disponibleGustos >= 0
                ? 'Te quedan \$${disponibleGustos.toStringAsFixed(2)} para gastar sin culpa'
                : 'Excedido por \$${(-disponibleGustos).toStringAsFixed(2)}',
            esSobrantePositivo: disponibleGustos >= 0,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ESTADO VACIO: CUANDO NO HAY INGRESOS AUN
  // ==========================================
  Widget _buildEstadoSinIngresos(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.tarjeta(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ColoresApp.borde(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ColoresApp.primarioVerde.withValues(alpha: 0.14),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: ColoresApp.primarioVerde,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Presupuesto 50 / 20 / 30',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.texto(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Registra tus ingresos de este mes para activar automáticamente la regla 50/20/30 (50% deudas, 20% ahorro y 30% gustos). Todo lo que ahorres en deudas se transferirá a tu meta de ahorro.',
            style: TextStyle(
              fontSize: 13,
              color: ColoresApp.subtexto(context),
              height: 1.4,
            ),
          ),
          if (alPulsarRegistrarIngreso != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: alPulsarRegistrarIngreso,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Registrar un Ingreso'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColoresApp.primarioVerde,
                side: const BorderSide(color: ColoresApp.primarioVerde),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGO MODAL EXPLICATIVO DE LA REGLA
  // ==========================================
  void _mostrarModalExplicativo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ColoresApp.tarjeta(context),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Regla 50 / 20 / 30 Dinámica',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.texto(context),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta fórmula divide tus ingresos mensuales de forma equilibrada para vivir sin deudas y acelerar tu patrimonio:',
                style: TextStyle(
                  fontSize: 13,
                  color: ColoresApp.subtexto(context),
                ),
              ),
              const SizedBox(height: 14),
              _buildFilaExplicacion(
                '💳 50% para Deudas & Fijos',
                'Destinado a tarjetas de crédito, deudas pendientes y gastos fijos mensuales.',
                const Color(0xFF5C6BC0),
              ),
              const SizedBox(height: 10),
              _buildFilaExplicacion(
                '🎯 20% para Ahorro & Metas',
                'Tu colchón financiero y compras planificadas.',
                ColoresApp.primarioVerde,
              ),
              const SizedBox(height: 10),
              _buildFilaExplicacion(
                '🛍️ 30% para Gustos & Estilo',
                'Ocio, salidas, entretenimiento y compras libres de culpa.',
                const Color(0xFFFB8C00),
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Regla del Sobrante: Si tus compromisos de deudas son menores al 50%, el dinero restante se suma inmediatamente a tu bolsa de ahorro.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.texto(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaExplicacion(String titulo, String desc, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: BARRA INDIVIDUAL DE BOLSA
// ==========================================
class _ItemPresupuestoBarra extends StatelessWidget {
  final String titulo;
  final String etiquetaPorcentaje;
  final double montoConsumido;
  final double montoCupo;
  final Color colorBarra;
  final IconData icono;
  final String mensajePie;
  final bool esSobrantePositivo;

  const _ItemPresupuestoBarra({
    required this.titulo,
    required this.etiquetaPorcentaje,
    required this.montoConsumido,
    required this.montoCupo,
    required this.colorBarra,
    required this.icono,
    required this.mensajePie,
    required this.esSobrantePositivo,
  });

  @override
  Widget build(BuildContext context) {
    final double progreso = montoCupo > 0
        ? (montoConsumido / montoCupo).clamp(0.0, 1.0)
        : 0.0;
    final int porcentajeConsumo = montoCupo > 0
        ? ((montoConsumido / montoCupo) * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.esOscuro(context)
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColoresApp.esOscuro(context)
              ? Colors.white10
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Icono, Título y Badge del porcentaje asignado
          Row(
            children: [
              Icon(icono, size: 16, color: colorBarra),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.texto(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorBarra.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  etiquetaPorcentaje,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorBarra,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Monto consumido vs Cupo asignado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${montoConsumido.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorBarra,
                ),
              ),
              Text(
                'de \$${montoCupo.toStringAsFixed(2)} ($porcentajeConsumo%)',
                style: TextStyle(
                  fontSize: 12,
                  color: ColoresApp.subtexto(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Barra de progreso estilizada
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: ColoresApp.esOscuro(context)
                  ? Colors.white12
                  : Colors.grey.shade200,
              color: colorBarra,
            ),
          ),
          const SizedBox(height: 6),

          // Mensaje de pie de barra
          Text(
            mensajePie,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: esSobrantePositivo
                  ? ColoresApp.subtexto(context)
                  : ColoresApp.gastoRojo,
            ),
          ),
        ],
      ),
    );
  }
}
