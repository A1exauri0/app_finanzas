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
import '../modelos/gasto_fijo_modelo.dart';

// ==========================================
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/cards/gastos_fijos_resumen_card.dart';
import '../componentes/modales/editar_tarjeta_modal.dart';
import '../componentes/modales/editar_deuda_persona_modal.dart';
import '../componentes/comunes/boton_modo_oscuro.dart';

// ==========================================
// PANTALLA: CONTROL DE DEUDAS Y TARJETAS
// ==========================================
class DeudasScreen extends StatefulWidget {
  final List<DeudaModelo> listaDeudas;
  final List<GastoFijoModelo> listaGastosFijos;
  final Function(DeudaModelo) alAgregarDeuda;
  final Function(DeudaModelo) alActualizarTarjeta;
  final Function(DeudaModelo) alActualizarDeudaPersona;
  final Function(String idDeuda) alEliminarDeuda;
  final Function(String idDeuda, double montoAbono) alAbonarDeuda;
  final Function(String idTarjeta, int nuevoDiaCorte) alEditarDiaCorte;
  final Function(String idDeuda, String concepto, double monto, DateTime fecha)
  alAcumularPrestamo;
  final VoidCallback alPulsarNuevoGastoFijo;
  final Function(GastoFijoModelo) alMarcarGastoFijoPagado;
  final Function(GastoFijoModelo) alEditarGastoFijo;
  final Function(GastoFijoModelo) alEliminarGastoFijo;
  final Function(int)? alCambiarSubPestana;
  final VoidCallback? alAbrirMenuLateral;
  final VoidCallback? alCerrarVentana;

  const DeudasScreen({
    super.key,
    required this.listaDeudas,
    this.listaGastosFijos = const [],
    required this.alAgregarDeuda,
    required this.alActualizarTarjeta,
    required this.alActualizarDeudaPersona,
    required this.alEliminarDeuda,
    required this.alAbonarDeuda,
    required this.alEditarDiaCorte,
    required this.alAcumularPrestamo,
    required this.alPulsarNuevoGastoFijo,
    required this.alMarcarGastoFijoPagado,
    required this.alEditarGastoFijo,
    required this.alEliminarGastoFijo,
    this.alCambiarSubPestana,
    this.alAbrirMenuLateral,
    this.alCerrarVentana,
  });

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabControlador;

  @override
  void initState() {
    super.initState();
    _tabControlador = TabController(length: 4, vsync: this);
    _tabControlador.addListener(() {
      if (!_tabControlador.indexIsChanging) {
        widget.alCambiarSubPestana?.call(_tabControlador.index);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabControlador.dispose();
    super.dispose();
  }

  // Ventana modal (Dialog) para editar tarjeta de crédito
  void _mostrarModalEditarTarjeta(DeudaModelo tarjeta) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EditarTarjetaModal(
        tarjeta: tarjeta,
        alGuardarCambios: widget.alActualizarTarjeta,
      ),
    );
  }

  // Ventana modal (Dialog) para editar persona o deuda de tercero
  void _mostrarModalEditarPersona(DeudaModelo deuda) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EditarDeudaPersonaModal(
        deuda: deuda,
        alGuardarCambios: widget.alActualizarDeudaPersona,
      ),
    );
  }

  // Diálogo para confirmar eliminación de tarjeta o deuda
  void _confirmarEliminar(DeudaModelo deuda) {
    final bool esTarjeta = deuda.tipoDeuda == TipoDeuda.tarjetaCredito;
    final String etiqueta = esTarjeta ? 'la tarjeta' : 'la deuda de';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar $etiqueta "${deuda.tituloOEntidad}"?'),
        content: Text(
          'Se eliminará este registro ${esTarjeta ? "y todo su historial de pagos" : "y sus partidas acumuladas"}.\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColoresApp.gastoRojo,
            ),
            onPressed: () {
              widget.alEliminarDeuda(deuda.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Registro de "${deuda.tituloOEntidad}" eliminado',
                  ),
                  backgroundColor: ColoresApp.gastoRojo,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Selector de fecha de calendario para editar el día de corte
  Future<void> _mostrarDialogoEditarCorte(DeudaModelo tarjeta) async {
    final DateTime ahora = DateTime.now();
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      helpText:
          'NUEVO DÍA DE CORTE PARA ${tarjeta.tituloOEntidad.toUpperCase()}',
      initialDate: DateTime(ahora.year, ahora.month, tarjeta.diaCorte ?? 15),
      firstDate: DateTime(ahora.year, ahora.month, 1),
      lastDate: DateTime(ahora.year, ahora.month, 31),
    );

    if (fechaElegida != null && mounted) {
      widget.alEditarDiaCorte(tarjeta.id, fechaElegida.day);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Día de corte de ${tarjeta.tituloOEntidad} actualizado al día ${fechaElegida.day}',
          ),
          backgroundColor: ColoresApp.primarioVerde,
        ),
      );
    }
  }

  // Modal para realizar un abono o pago rápido
  void _mostrarDialogoAbonar(DeudaModelo deuda) {
    final TextEditingController abonoControlador = TextEditingController();
    final bool esMeDeben = deuda.tipoDeuda == TipoDeuda.meDeben;
    final bool esTarjeta = deuda.tipoDeuda == TipoDeuda.tarjetaCredito;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          esTarjeta
              ? 'Pagar Tarjeta ${deuda.tituloOEntidad}'
              : (esMeDeben
                    ? 'Registrar Cobro a ${deuda.tituloOEntidad}'
                    : 'Pagar a ${deuda.tituloOEntidad}'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo actual pendiente: \$${deuda.montoPendiente.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: abonoControlador,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar o abonar (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final double? monto = double.tryParse(
                abonoControlador.text.replaceAll(',', ''),
              );
              if (monto != null && monto > 0) {
                widget.alAbonarDeuda(deuda.id, monto);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pago de \$${monto.toStringAsFixed(2)} registrado con éxito',
                    ),
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

  // Diálogo para ver el historial de pagos y compras de una tarjeta de crédito
  void _mostrarHistorialTarjeta(DeudaModelo tarjeta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: tarjeta.colorTarjeta ?? Colors.purple,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Historial: ${tarjeta.tituloOEntidad}')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo actual a pagar: \$${tarjeta.montoPendiente.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              if (tarjeta.historialPartidas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No hay pagos ni compras registradas aún en esta tarjeta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.textoSecundario),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tarjeta.historialPartidas.length,
                    itemBuilder: (context, i) {
                      final p = tarjeta.historialPartidas[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: p.esAbono
                              ? Colors.green.shade50
                              : Colors.purple.shade50,
                          child: Icon(
                            p.esAbono
                                ? Icons.arrow_downward_rounded
                                : Icons.shopping_bag_outlined,
                            size: 14,
                            color: p.esAbono ? Colors.green : Colors.purple,
                          ),
                        ),
                        title: Text(
                          p.concepto,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                        ),
                        trailing: Text(
                          '${p.esAbono ? "-" : "+"}\$${p.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.esAbono ? Colors.green : Colors.purple,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para ver el historial acumulativo de una persona
  void _mostrarHistorialPersona(DeudaModelo persona) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: ColoresApp.primarioVerde),
            const SizedBox(width: 8),
            Expanded(child: Text('Historial: ${persona.tituloOEntidad}')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo pendiente total: \$${persona.montoPendiente.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              if (persona.historialPartidas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No hay desglose de partidas registradas para esta persona.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.textoSecundario),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: persona.historialPartidas.length,
                    itemBuilder: (context, i) {
                      final p = persona.historialPartidas[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: p.esAbono
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: Icon(
                            p.esAbono
                                ? Icons.arrow_downward_rounded
                                : Icons.add_rounded,
                            size: 14,
                            color: p.esAbono
                                ? Colors.green
                                : Colors.orange.shade800,
                          ),
                        ),
                        title: Text(
                          p.concepto,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                        ),
                        trailing: Text(
                          '${p.esAbono ? "-" : "+"}\$${p.monto.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: p.esAbono
                                ? Colors.green
                                : Colors.orange.shade900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar deudas: no saldadas primero (más recientes arriba), saldadas al fondo
    List<DeudaModelo> ordenarDeudas(List<DeudaModelo> items) {
      final pendientes = items.where((d) => !d.estaSaldada).toList();
      final saldadas = items.where((d) => d.estaSaldada).toList();
      return [...pendientes, ...saldadas];
    }

    final List<DeudaModelo> tarjetas = ordenarDeudas(
      widget.listaDeudas
          .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
          .toList(),
    );
    final List<DeudaModelo> meDeben = ordenarDeudas(
      widget.listaDeudas
          .where((d) => d.tipoDeuda == TipoDeuda.meDeben)
          .toList(),
    );
    final List<DeudaModelo> debo = ordenarDeudas(
      widget.listaDeudas
          .where((d) => d.tipoDeuda == TipoDeuda.debo)
          .toList(),
    );

    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      appBar: AppBar(
        title: Text(
          'Deudas & Compromisos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColoresApp.texto(context),
          ),
        ),
        backgroundColor: ColoresApp.fondo(context),
        elevation: 0,
        leading: widget.alAbrirMenuLateral != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menú principal',
                onPressed: widget.alAbrirMenuLateral,
              )
            : null,
        actions: [
          const BotonModoOscuro(),
          if (widget.alCerrarVentana != null)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cerrar ventana',
              onPressed: widget.alCerrarVentana,
            ),
        ],
        bottom: TabBar(
          controller: _tabControlador,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: ColoresApp.primarioVerde,
          labelColor: ColoresApp.primarioVerde,
          unselectedLabelColor: ColoresApp.subtexto(context),
          tabs: const [
            Tab(icon: Icon(Icons.credit_card_rounded), text: 'Tarjetas'),
            Tab(icon: Icon(Icons.handshake_rounded), text: 'Me Deben'),
            Tab(icon: Icon(Icons.money_off_csred_rounded), text: 'Debo'),
            Tab(icon: Icon(Icons.repeat_rounded), text: 'Gastos Fijos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabControlador,
        children: [
          _ListaTarjetasVista(
            tarjetas: tarjetas,
            alPulsarPagar: _mostrarDialogoAbonar,
            alPulsarEditarCorte: _mostrarDialogoEditarCorte,
            alPulsarEditarCompleto: _mostrarModalEditarTarjeta,
            alPulsarVerHistorial: _mostrarHistorialTarjeta,
            alPulsarEliminar: _confirmarEliminar,
          ),
          _ListaDeudasVista(
            lista: meDeben,
            tipo: TipoDeuda.meDeben,
            alPulsarAbonar: _mostrarDialogoAbonar,
            alPulsarVerHistorial: _mostrarHistorialPersona,
            alPulsarEditar: _mostrarModalEditarPersona,
            alPulsarEliminar: _confirmarEliminar,
          ),
          _ListaDeudasVista(
            lista: debo,
            tipo: TipoDeuda.debo,
            alPulsarAbonar: _mostrarDialogoAbonar,
            alPulsarVerHistorial: _mostrarHistorialPersona,
            alPulsarEditar: _mostrarModalEditarPersona,
            alPulsarEliminar: _confirmarEliminar,
          ),
          // Vista 4: Suscripciones y Gastos Fijos
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 90,
            ),
            child: GastosFijosResumenCard(
              listaGastosFijos: widget.listaGastosFijos,
              alPulsarNuevoGastoFijo: widget.alPulsarNuevoGastoFijo,
              alMarcarPagado: widget.alMarcarGastoFijoPagado,
              alEditarGastoFijo: widget.alEditarGastoFijo,
              alEliminarGastoFijo: widget.alEliminarGastoFijo,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: VISTA ESPECIALIZADA DE TARJETAS
// ==========================================
class _ListaTarjetasVista extends StatelessWidget {
  final List<DeudaModelo> tarjetas;
  final Function(DeudaModelo) alPulsarPagar;
  final Function(DeudaModelo) alPulsarEditarCorte;
  final Function(DeudaModelo) alPulsarEditarCompleto;
  final Function(DeudaModelo) alPulsarVerHistorial;
  final Function(DeudaModelo) alPulsarEliminar;

  const _ListaTarjetasVista({
    required this.tarjetas,
    required this.alPulsarPagar,
    required this.alPulsarEditarCorte,
    required this.alPulsarEditarCompleto,
    required this.alPulsarVerHistorial,
    required this.alPulsarEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (tarjetas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No tienes tarjetas registradas',
              style: TextStyle(color: ColoresApp.textoSecundario),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: tarjetas.length,
      itemBuilder: (context, index) {
        final tarjeta = tarjetas[index];
        final Color colorBase = tarjeta.colorTarjeta ?? const Color(0xFF263238);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorBase, colorBase.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colorBase.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior responsiva: Nombre, chip de corte y menú de 3 puntos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarjeta.tituloOEntidad,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              decoration: tarjeta.estaSaldada
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.white70,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chip interactivo para ver y modificar el día de corte
                      InkWell(
                        onTap: () => alPulsarEditarCorte(tarjeta),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_calendar_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                tarjeta.diaCorte != null
                                    ? 'Corte: Día ${tarjeta.diaCorte}'
                                    : 'Definir Corte',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Menú desplegable con 3 puntos (Historial, Editar, Eliminar)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (valor) {
                          if (valor == 'historial') {
                            alPulsarVerHistorial(tarjeta);
                          } else if (valor == 'editar') {
                            alPulsarEditarCompleto(tarjeta);
                          } else if (valor == 'eliminar') {
                            alPulsarEliminar(tarjeta);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem<String>(
                            value: 'historial',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: ColoresApp.textoPrincipal,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('Ver Historial de Pagos'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: ColoresApp.textoPrincipal,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('Editar Parámetros y Límites'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'eliminar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: ColoresApp.gastoRojo,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Eliminar Tarjeta',
                                  style: TextStyle(color: ColoresApp.gastoRojo),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Saldos responsivos: A pagar vs Disponible
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Usado a Pagar',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '\$${tarjeta.montoPendiente.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Crédito Disponible',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '\$${tarjeta.creditoDisponible.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Barra de consumo de crédito
              LinearProgressIndicator(
                value: tarjeta.limiteEfectivo > 0
                    ? (tarjeta.montoPendiente / tarjeta.limiteEfectivo).clamp(
                        0.0,
                        1.0,
                      )
                    : 0.0,
                backgroundColor: Colors.white24,
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                minHeight: 6,
              ),
              const SizedBox(height: 6),

              // Indicadores de límites
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Límite Banco: \$${tarjeta.montoTotal.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  if (tarjeta.limiteAjustado != null &&
                      tarjeta.limiteAjustado! > 0)
                    Text(
                      'Tope Personal: \$${tarjeta.limiteAjustado!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (tarjeta.fechaLimitePago != null)
                    Text(
                      'Pagar antes: ${tarjeta.fechaLimitePago!.day}/${tarjeta.fechaLimitePago!.month}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón para Pagar Tarjeta
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => alPulsarPagar(tarjeta),
                  icon: const Icon(
                    Icons.payment_rounded,
                    color: Colors.black87,
                    size: 18,
                  ),
                  label: const Text(
                    'Pagar o Abonar Tarjeta',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: LISTADO DE DEUDAS Y DEUDORES
// ==========================================
class _ListaDeudasVista extends StatelessWidget {
  final List<DeudaModelo> lista;
  final TipoDeuda tipo;
  final Function(DeudaModelo) alPulsarAbonar;
  final Function(DeudaModelo) alPulsarVerHistorial;
  final Function(DeudaModelo) alPulsarEditar;
  final Function(DeudaModelo) alPulsarEliminar;

  const _ListaDeudasVista({
    required this.lista,
    required this.tipo,
    required this.alPulsarAbonar,
    required this.alPulsarVerHistorial,
    required this.alPulsarEditar,
    required this.alPulsarEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              tipo == TipoDeuda.meDeben
                  ? 'No hay personas que te deban dinero'
                  : '¡Felicidades! No tienes deudas registradas',
              style: const TextStyle(color: ColoresApp.textoSecundario),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final deuda = lista[index];
        final bool esMeDeben = tipo == TipoDeuda.meDeben;
        final bool saldada = deuda.estaSaldada;

        return Card(
          elevation: saldada ? 0 : 1,
          color: saldada
              ? (ColoresApp.esOscuro(context)
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade100)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: saldada
                ? BorderSide(
                    color: ColoresApp.esOscuro(context)
                        ? Colors.white12
                        : Colors.grey.shade300,
                  )
                : BorderSide.none,
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de persona responsivo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: saldada
                                ? Colors.grey.shade200
                                : (esMeDeben
                                    ? Colors.green.shade50
                                    : Colors.red.shade50),
                            child: Icon(
                              saldada
                                  ? Icons.check_circle_rounded
                                  : (esMeDeben
                                      ? Icons.person_pin_rounded
                                      : Icons.account_balance_rounded),
                              color: saldada
                                  ? Colors.grey.shade600
                                  : (esMeDeben
                                      ? ColoresApp.ingresoVerde
                                      : ColoresApp.gastoRojo),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        deuda.tituloOEntidad,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: saldada
                                              ? ColoresApp.subtexto(context)
                                              : ColoresApp.texto(context),
                                          decoration: saldada
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          decorationColor: ColoresApp.subtexto(context),
                                          decorationThickness: 2,
                                        ),
                                      ),
                                    ),
                                    if (saldada) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'PAGADO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (deuda.historialPartidas.isNotEmpty)
                                  Text(
                                    '${deuda.historialPartidas.length} registros acumulados',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColoresApp.subtexto(context),
                                      decoration: saldada
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Menú de 3 puntos (Historial, Editar, Eliminar)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: ColoresApp.subtexto(context),
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (valor) {
                        if (valor == 'historial') {
                          alPulsarVerHistorial(deuda);
                        } else if (valor == 'editar') {
                          alPulsarEditar(deuda);
                        } else if (valor == 'eliminar') {
                          alPulsarEliminar(deuda);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          value: 'historial',
                          child: Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: ColoresApp.texto(context),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text('Ver Historial Completo'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: ColoresApp.texto(context),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text('Editar Registro'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: ColoresApp.gastoRojo,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Eliminar Registro',
                                style: TextStyle(color: ColoresApp.gastoRojo),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                LinearProgressIndicator(
                  value: deuda.porcentajePagado,
                  backgroundColor: Colors.grey.shade200,
                  color: saldada
                      ? Colors.green
                      : (esMeDeben
                          ? ColoresApp.ingresoVerde
                          : ColoresApp.gastoRojo),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 7,
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total prestado/acumulado',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColoresApp.subtexto(context),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '\$${deuda.montoTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: saldada
                                    ? ColoresApp.subtexto(context)
                                    : ColoresApp.texto(context),
                                decoration: saldada
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: ColoresApp.subtexto(context),
                                decorationThickness: 2,
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
                          Text(
                            'Falta por pagar',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColoresApp.subtexto(context),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              saldada
                                  ? 'Saldado (\$0.00)'
                                  : '\$${deuda.montoPendiente.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: saldada
                                    ? Colors.green
                                    : (esMeDeben
                                          ? Colors.amber.shade900
                                          : ColoresApp.gastoRojo),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    if (!deuda.estaSaldada)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => alPulsarAbonar(deuda),
                          icon: const Icon(Icons.price_check_rounded, size: 18),
                          label: Text(
                            esMeDeben ? 'Registrar Cobro' : 'Abonar a Deuda',
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
