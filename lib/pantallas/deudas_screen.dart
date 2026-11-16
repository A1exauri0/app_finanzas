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
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/nueva_deuda_modal.dart';

// ==========================================
// PANTALLA: CONTROL DE DEUDAS Y TARJETAS
// ==========================================
class DeudasScreen extends StatefulWidget {
  final List<DeudaModelo> listaDeudas;
  final Function(DeudaModelo) alAgregarDeuda;
  final Function(String idDeuda, double montoAbono) alAbonarDeuda;

  const DeudasScreen({
    super.key,
    required this.listaDeudas,
    required this.alAgregarDeuda,
    required this.alAbonarDeuda,
  });

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabControlador;

  @override
  void initState() {
    super.initState();
    _tabControlador = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabControlador.dispose();
    super.dispose();
  }

  // Abrir modal para crear una nueva deuda o tarjeta
  void _mostrarModalNuevaDeuda() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevaDeudaModal(
        alGuardarDeuda: widget.alAgregarDeuda,
      ),
    );
  }

  // Modal para realizar un abono o pago rápido
  void _mostrarDialogoAbonar(DeudaModelo deuda) {
    final TextEditingController abonoControlador = TextEditingController();
    final bool esMeDeben = deuda.tipoDeuda == TipoDeuda.meDeben;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esMeDeben ? 'Registrar Cobro' : 'Pagar Tarjeta / Deuda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entidad: ${deuda.tituloOEntidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Saldo pendiente actual: \$${deuda.montoPendiente.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: abonoControlador,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar o abonar (\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final double? monto = double.tryParse(abonoControlador.text.replaceAll(',', ''));
              if (monto != null && monto > 0) {
                widget.alAbonarDeuda(deuda.id, monto);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago de \$${monto.toStringAsFixed(2)} registrado con éxito'),
                    backgroundColor: ColoresApp.primarioVerde,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtros por pestaña
    final List<DeudaModelo> meDeben =
        widget.listaDeudas.where((d) => d.tipoDeuda == TipoDeuda.meDeben).toList();
    final List<DeudaModelo> debo =
        widget.listaDeudas.where((d) => d.tipoDeuda == TipoDeuda.debo).toList();
    final List<DeudaModelo> tarjetas =
        widget.listaDeudas.where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito).toList();

    return Scaffold(
      backgroundColor: ColoresApp.fondoClaro,
      appBar: AppBar(
        title: const Text('Gestión de Deudas y Créditos'),
        backgroundColor: ColoresApp.fondoClaro,
        elevation: 0,
        bottom: TabBar(
          controller: _tabControlador,
          indicatorColor: ColoresApp.primarioVerde,
          labelColor: ColoresApp.primarioVerde,
          unselectedLabelColor: ColoresApp.textoSecundario,
          tabs: const [
            Tab(icon: Icon(Icons.handshake_rounded), text: 'Me Deben'),
            Tab(icon: Icon(Icons.money_off_csred_rounded), text: 'Debo'),
            Tab(icon: Icon(Icons.credit_card_rounded), text: 'Tarjetas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabControlador,
        children: [
          _ListaDeudasVista(
            lista: meDeben,
            tipo: TipoDeuda.meDeben,
            alPulsarAbonar: _mostrarDialogoAbonar,
          ),
          _ListaDeudasVista(
            lista: debo,
            tipo: TipoDeuda.debo,
            alPulsarAbonar: _mostrarDialogoAbonar,
          ),
          _ListaDeudasVista(
            lista: tarjetas,
            tipo: TipoDeuda.tarjetaCredito,
            alPulsarAbonar: _mostrarDialogoAbonar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevaDeuda,
        backgroundColor: ColoresApp.primarioVerde,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nueva Deuda / Tarjeta', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: LISTADO SEGUN CATEGORIA
// ==========================================
class _ListaDeudasVista extends StatelessWidget {
  final List<DeudaModelo> lista;
  final TipoDeuda tipo;
  final Function(DeudaModelo) alPulsarAbonar;

  const _ListaDeudasVista({
    required this.lista,
    required this.tipo,
    required this.alPulsarAbonar,
  });

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tipo == TipoDeuda.tarjetaCredito
                  ? Icons.credit_card_off_rounded
                  : Icons.check_circle_outline_rounded,
              size: 54,
              color: ColoresApp.textoSecundario.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              tipo == TipoDeuda.meDeben
                  ? 'No hay personas que te deban dinero'
                  : (tipo == TipoDeuda.tarjetaCredito
                      ? 'No tienes tarjetas de crédito registradas'
                      : '¡Felicidades! No tienes deudas registradas'),
              style: const TextStyle(color: ColoresApp.textoSecundario),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final deuda = lista[index];
        final bool esTarjeta = tipo == TipoDeuda.tarjetaCredito;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: esTarjeta
                              ? Colors.purple.shade50
                              : (tipo == TipoDeuda.meDeben
                                  ? Colors.green.shade50
                                  : Colors.red.shade50),
                          child: Icon(
                            esTarjeta
                                ? Icons.credit_card_rounded
                                : (tipo == TipoDeuda.meDeben
                                    ? Icons.person_pin_rounded
                                    : Icons.account_balance_rounded),
                            color: esTarjeta
                                ? Colors.purple
                                : (tipo == TipoDeuda.meDeben
                                    ? ColoresApp.ingresoVerde
                                    : ColoresApp.gastoRojo),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deuda.tituloOEntidad,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.textoPrincipal,
                              ),
                            ),
                            if (deuda.diaCorte != null)
                              Text(
                                'Corte los días ${deuda.diaCorte} de cada mes',
                                style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (deuda.estaSaldada)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Saldada',
                          style: TextStyle(
                            color: ColoresApp.ingresoVerde,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barra de progreso y montos
                LinearProgressIndicator(
                  value: deuda.porcentajePagado,
                  backgroundColor: Colors.grey.shade200,
                  color: tipo == TipoDeuda.meDeben
                      ? ColoresApp.ingresoVerde
                      : (esTarjeta ? Colors.purple : ColoresApp.gastoRojo),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 7,
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esTarjeta ? 'Límite Total' : 'Total original',
                          style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                        ),
                        Text(
                          '\$${deuda.montoTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          esTarjeta ? 'Saldo a Pagar' : 'Falta por pagar',
                          style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario),
                        ),
                        Text(
                          '\$${deuda.montoPendiente.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: deuda.estaSaldada
                                ? ColoresApp.ingresoVerde
                                : (tipo == TipoDeuda.meDeben
                                    ? Colors.amber.shade900
                                    : ColoresApp.gastoRojo),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Botón de acción para pagar / abonar
                if (!deuda.estaSaldada)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => alPulsarAbonar(deuda),
                      icon: Icon(
                        esTarjeta ? Icons.payment_rounded : Icons.price_check_rounded,
                        size: 18,
                      ),
                      label: Text(
                        esTarjeta
                            ? 'Pagar Tarjeta'
                            : (tipo == TipoDeuda.meDeben ? 'Registrar Cobro' : 'Abonar a Deuda'),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
