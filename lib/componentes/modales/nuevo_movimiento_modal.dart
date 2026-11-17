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

// ==========================================
// ENUMERADOR PARA METODO DE PAGO EN GASTOS
// ==========================================
enum MetodoPagoGasto {
  efectivoDebito,
  tarjetaCredito,
}

// ==========================================
// COMPONENTE VISUAL: MODAL PARA NUEVO MOVIMIENTO
// ==========================================
class NuevoMovimientoModal extends StatefulWidget {
  final TipoMovimiento tipoInicial;
  final List<DeudaModelo> listaDeudasActivas;
  final double dineroDisponible;
  final Function(MovimientoModelo) alGuardarMovimiento;

  const NuevoMovimientoModal({
    super.key,
    required this.tipoInicial,
    this.listaDeudasActivas = const [],
    this.dineroDisponible = 0.0,
    required this.alGuardarMovimiento,
  });

  @override
  State<NuevoMovimientoModal> createState() => _NuevoMovimientoModalState();
}

class _NuevoMovimientoModalState extends State<NuevoMovimientoModal> {
  // Clave global para validar el formulario
  final _formularioClave = GlobalKey<FormState>();

  // Controladores de texto para los campos
  final TextEditingController _montoControlador = TextEditingController();
  final TextEditingController _conceptoControlador = TextEditingController();

  // Estados locales del formulario
  late TipoMovimiento _tipoSeleccionado;
  late DateTime _fechaSeleccionada;
  late String _categoriaSeleccionada;
  late IconData _iconoSeleccionado;

  // Estado para vincular cobro o abono a deuda
  String? _deudaSeleccionadaId;

  // Estado para método de pago al hacer un gasto
  MetodoPagoGasto _metodoPago = MetodoPagoGasto.efectivoDebito;
  String? _tarjetaGastoSeleccionadaId;

  // Categorías para Ingresos
  static const List<Map<String, dynamic>> _categoriasIngreso = [
    {'nombre': 'Sueldo', 'icono': Icons.account_balance_wallet_rounded},
    {'nombre': 'Cobro de Deuda', 'icono': Icons.handshake_rounded},
    {'nombre': 'Ingreso Extra', 'icono': Icons.monetization_on_rounded},
    {'nombre': 'Ventas', 'icono': Icons.storefront_rounded},
    {'nombre': 'Otro Ingreso', 'icono': Icons.add_circle_outline_rounded},
  ];

  // Categorías para Gastos
  static const List<Map<String, dynamic>> _categoriasGasto = [
    {'nombre': 'Alimentación', 'icono': Icons.shopping_cart_rounded},
    {'nombre': 'Transporte', 'icono': Icons.directions_bus_rounded},
    {'nombre': 'Servicios', 'icono': Icons.wifi_rounded},
    {'nombre': 'Entretenimiento', 'icono': Icons.movie_rounded},
    {'nombre': 'Salud', 'icono': Icons.medical_services_rounded},
    {'nombre': 'Educación', 'icono': Icons.school_rounded},
    {'nombre': 'Pago de Deuda / Tarjeta', 'icono': Icons.payment_rounded},
    {'nombre': 'Otro Gasto', 'icono': Icons.remove_circle_outline_rounded},
  ];

  List<Map<String, dynamic>> get _categoriasActuales =>
      _tipoSeleccionado == TipoMovimiento.ingreso
          ? _categoriasIngreso
          : _categoriasGasto;

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.tipoInicial;
    _fechaSeleccionada = DateTime.now();

    // Listener para recalcular alertas de saldo y crédito en tiempo real
    _montoControlador.addListener(() {
      setState(() {});
    });

    final categoriasIniciales = _categoriasActuales;
    _categoriaSeleccionada = categoriasIniciales.first['nombre'] as String;
    _iconoSeleccionado = categoriasIniciales.first['icono'] as IconData;

    // Seleccionamos la primera tarjeta de crédito si existe
    final tarjetasCredito = widget.listaDeudasActivas
        .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
        .toList();
    if (tarjetasCredito.isNotEmpty) {
      _tarjetaGastoSeleccionadaId = tarjetasCredito.first.id;
    }
  }

  // Getters para verificación de sobregiro
  double get _montoIngresadoActual {
    final texto = _montoControlador.text.replaceAll(',', '').trim();
    return double.tryParse(texto) ?? 0.0;
  }

  DeudaModelo? get _tarjetaSeleccionadaActual {
    if (_tarjetaGastoSeleccionadaId == null) return null;
    try {
      return widget.listaDeudasActivas.firstWhere(
        (d) => d.id == _tarjetaGastoSeleccionadaId,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _estaSobregiradoEfectivo {
    if (_tipoSeleccionado != TipoMovimiento.gasto) return false;
    if (_metodoPago == MetodoPagoGasto.tarjetaCredito) return false;
    if (_montoIngresadoActual <= 0) return false;
    return _montoIngresadoActual > widget.dineroDisponible;
  }

  bool get _estaSobregiradoTarjeta {
    if (_tipoSeleccionado != TipoMovimiento.gasto) return false;
    if (_metodoPago != MetodoPagoGasto.tarjetaCredito) return false;
    if (_montoIngresadoActual <= 0) return false;
    final tarjeta = _tarjetaSeleccionadaActual;
    if (tarjeta == null) return false;
    return _montoIngresadoActual > tarjeta.creditoDisponible;
  }

  @override
  void dispose() {
    _montoControlador.dispose();
    _conceptoControlador.dispose();
    super.dispose();
  }

  // Cambio de tipo (Ingreso / Gasto) y actualización de categorías
  void _cambiarTipoMovimiento(TipoMovimiento nuevoTipo) {
    setState(() {
      _tipoSeleccionado = nuevoTipo;
      final nuevasCategorias = _categoriasActuales;
      _categoriaSeleccionada = nuevasCategorias.first['nombre'] as String;
      _iconoSeleccionado = nuevasCategorias.first['icono'] as IconData;
      _deudaSeleccionadaId = null;
    });
  }

  // Método para guardar y emitir el nuevo movimiento
  void _guardarFormulario() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double? monto = double.tryParse(_montoControlador.text.replaceAll(',', ''));
      if (monto == null || monto <= 0) return;

      // Si hay sobregiro en efectivo o tarjeta, pedimos confirmación de advertencia
      if (_estaSobregiradoEfectivo) {
        _mostrarDialogoConfirmacionSobregiro(
          titulo: '⚠️ Advertencia de Sobregiro en Efectivo',
          mensaje:
              'Estás intentando gastar \$${monto.toStringAsFixed(2)}, pero tu dinero disponible es de \$${widget.dineroDisponible.toStringAsFixed(2)}.\n\nQuedarás sobregirado por \$${(monto - widget.dineroDisponible).toStringAsFixed(2)}.\n\n¿Deseas registrar este gasto de todos modos?',
          alConfirmar: () => _procesarGuardado(monto),
        );
        return;
      }

      if (_estaSobregiradoTarjeta) {
        final tarjeta = _tarjetaSeleccionadaActual!;
        _mostrarDialogoConfirmacionSobregiro(
          titulo: '⚠️ Límite de Tarjeta Excedido',
          mensaje:
              'El gasto de \$${monto.toStringAsFixed(2)} excede el crédito disponible de ${tarjeta.tituloOEntidad} (\$${tarjeta.creditoDisponible.toStringAsFixed(2)}).\n\n¿Deseas forzar el registro de este gasto en la tarjeta?',
          alConfirmar: () => _procesarGuardado(monto),
        );
        return;
      }

      _procesarGuardado(monto);
    }
  }

  // Diálogo modal de advertencia al intentar gastar de más
  void _mostrarDialogoConfirmacionSobregiro({
    required String titulo,
    required String mensaje,
    required VoidCallback alConfirmar,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(mensaje, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar y Corregir'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.gastoRojo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              alConfirmar();
            },
            child: const Text('Registrar de Todas Formas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Procesamiento final y emisión
  void _procesarGuardado(double monto) {
    final bool esGastoConTarjeta = _tipoSeleccionado == TipoMovimiento.gasto &&
        _categoriaSeleccionada != 'Pago de Deuda / Tarjeta' &&
        _metodoPago == MetodoPagoGasto.tarjetaCredito;

    String? nombreDeudorOTarjeta;
    if (_deudaSeleccionadaId != null) {
      final deuda = widget.listaDeudasActivas.firstWhere(
        (d) => d.id == _deudaSeleccionadaId,
      );
      nombreDeudorOTarjeta = deuda.tituloOEntidad;
    }

    String? nombreTarjetaGasto;
    if (esGastoConTarjeta && _tarjetaGastoSeleccionadaId != null) {
      final tarjeta = widget.listaDeudasActivas.firstWhere(
        (d) => d.id == _tarjetaGastoSeleccionadaId,
      );
      nombreTarjetaGasto = tarjeta.tituloOEntidad;
    }

    final nuevoMovimiento = MovimientoModelo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: _conceptoControlador.text.trim(),
      monto: monto,
      fecha: _fechaSeleccionada,
      tipo: _tipoSeleccionado,
      icono: esGastoConTarjeta ? Icons.credit_card_rounded : _iconoSeleccionado,
      categoria: _categoriaSeleccionada,
      idDeudaAsociada: _deudaSeleccionadaId,
      nombreDeudorAsociado: nombreDeudorOTarjeta,
      pagadoConTarjeta: esGastoConTarjeta,
      idTarjetaUtilizada: esGastoConTarjeta ? _tarjetaGastoSeleccionadaId : null,
      nombreTarjetaUtilizada: nombreTarjetaGasto,
    );

    widget.alGuardarMovimiento(nuevoMovimiento);
    Navigator.of(context).pop();
  }

  // Método para seleccionar fecha con DatePicker
  Future<void> _abrirSelectorFecha() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _tipoSeleccionado == TipoMovimiento.ingreso
                  ? ColoresApp.ingresoVerde
                  : ColoresApp.gastoRojo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaElegida != null) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = _tipoSeleccionado == TipoMovimiento.ingreso;
    final Color colorActivo = esIngreso ? ColoresApp.ingresoVerde : ColoresApp.gastoRojo;

    // Detectamos operaciones de deudas
    final bool esCobroDeuda = esIngreso && _categoriaSeleccionada == 'Cobro de Deuda';
    final bool esAbonoDeuda = !esIngreso && _categoriaSeleccionada == 'Pago de Deuda / Tarjeta';
    final bool esGastoComun = !esIngreso && !esAbonoDeuda;

    // Filtramos deudas para cobro o abono
    final List<DeudaModelo> opcionesDeudas = esCobroDeuda
        ? widget.listaDeudasActivas.where((d) => d.tipoDeuda == TipoDeuda.meDeben && !d.estaSaldada).toList()
        : (esAbonoDeuda
            ? widget.listaDeudasActivas.where((d) => d.tipoDeuda != TipoDeuda.meDeben && !d.estaSaldada).toList()
            : []);

    // Tarjetas de crédito disponibles para pagar gastos
    final List<DeudaModelo> tarjetasCreditoDisponibles = widget.listaDeudasActivas
        .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formularioClave,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior de arrastre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título del Modal
              Text(
                esIngreso ? 'Registrar Ingreso' : 'Registrar Gasto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorActivo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Selector de tipo (Ingreso / Gasto)
              SegmentedButton<TipoMovimiento>(
                segments: const [
                  ButtonSegment(
                    value: TipoMovimiento.ingreso,
                    label: Text('Ingreso'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: TipoMovimiento.gasto,
                    label: Text('Gasto'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                ],
                selected: {_tipoSeleccionado},
                onSelectionChanged: (nuevaSeleccion) {
                  _cambiarTipoMovimiento(nuevaSeleccion.first);
                },
              ),
              const SizedBox(height: 20),

              // Selector de Método de Pago si es un GASTO común
              if (esGastoComun) ...[
                const Text(
                  '¿Con qué pagaste este gasto?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: 8),
                SegmentedButton<MetodoPagoGasto>(
                  segments: const [
                    ButtonSegment(
                      value: MetodoPagoGasto.efectivoDebito,
                      label: Text('Efectivo / Débito'),
                      icon: Icon(Icons.account_balance_wallet_rounded),
                    ),
                    ButtonSegment(
                      value: MetodoPagoGasto.tarjetaCredito,
                      label: Text('Tarjeta Crédito'),
                      icon: Icon(Icons.credit_card_rounded),
                    ),
                  ],
                  selected: {_metodoPago},
                  onSelectionChanged: (nuevoMetodo) {
                    setState(() {
                      _metodoPago = nuevoMetodo.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Si pagó con Tarjeta de Crédito, seleccionar con cuál
                if (_metodoPago == MetodoPagoGasto.tarjetaCredito) ...[
                  if (tarjetasCreditoDisponibles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aún no tienes tarjetas registradas. Registra una en la pestaña Tarjetas.',
                              style: TextStyle(fontSize: 12, color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _tarjetaGastoSeleccionadaId,
                      decoration: InputDecoration(
                        labelText: 'Selecciona la Tarjeta de Crédito',
                        prefixIcon: const Icon(Icons.credit_card_rounded, color: Colors.purple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        helperText: 'El monto se cargará al saldo pendiente de esta tarjeta.',
                      ),
                      items: tarjetasCreditoDisponibles.map((t) {
                        return DropdownMenuItem<String>(
                          value: t.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 7,
                                backgroundColor: t.colorTarjeta ?? Colors.purple,
                              ),
                              const SizedBox(width: 10),
                              Text('${t.tituloOEntidad} (Disp: \$${t.creditoDisponible.toStringAsFixed(0)})'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (idSeleccionada) {
                        setState(() {
                          _tarjetaGastoSeleccionadaId = idSeleccionada;
                        });
                      },
                      validator: (valor) {
                        if (_metodoPago == MetodoPagoGasto.tarjetaCredito && valor == null) {
                          return 'Selecciona la tarjeta';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ],

              // Campo de Monto
              TextFormField(
                controller: _montoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Monto (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded, color: colorActivo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: (_estaSobregiradoEfectivo || _estaSobregiradoTarjeta)
                          ? ColoresApp.gastoRojo
                          : colorActivo,
                      width: 2,
                    ),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa un monto válido';
                  }
                  final montoParsed = double.tryParse(valor.replaceAll(',', ''));
                  if (montoParsed == null || montoParsed <= 0) {
                    return 'Ingresa un número positivo';
                  }
                  return null;
                },
              ),

              // Indicador de disponibilidad y Alertas de Sobregiro en tiempo real
              if (!esIngreso) ...[
                const SizedBox(height: 6),
                if (_metodoPago != MetodoPagoGasto.tarjetaCredito)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 13,
                        color: widget.dineroDisponible >= 0
                            ? ColoresApp.textoSecundario
                            : ColoresApp.gastoRojo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dinero disponible: \$${widget.dineroDisponible.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.dineroDisponible >= 0
                              ? ColoresApp.textoSecundario
                              : ColoresApp.gastoRojo,
                        ),
                      ),
                    ],
                  ),

                // ALERTA VISUAL: Sobregiro en Efectivo
                if (_estaSobregiradoEfectivo)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ColoresApp.gastoRojo, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: ColoresApp.gastoRojo, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Gastas más de lo que tienes!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: ColoresApp.gastoRojo,
                                ),
                              ),
                              Text(
                                'Dispones de \$${widget.dineroDisponible.toStringAsFixed(2)}. Te sobregirarías por \$${(_montoIngresadoActual - widget.dineroDisponible).toStringAsFixed(2)}.',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ALERTA VISUAL: Límite de Tarjeta Excedido
                if (_estaSobregiradoTarjeta && _tarjetaSeleccionadaActual != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purple.shade700, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card_off_rounded, color: Colors.purple.shade800, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Superas el crédito disponible de ${_tarjetaSeleccionadaActual!.tituloOEntidad}!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                              Text(
                                'Crédito disponible: \$${_tarjetaSeleccionadaActual!.creditoDisponible.toStringAsFixed(2)}. Exceso: \$${(_montoIngresadoActual - _tarjetaSeleccionadaActual!.creditoDisponible).toStringAsFixed(2)}.',
                                style: TextStyle(fontSize: 12, color: Colors.purple.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),

              // Campo de Concepto o Descripción
              TextFormField(
                controller: _conceptoControlador,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Concepto o Descripción',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de Categoría (Dinámico según Ingreso o Gasto)
              DropdownButtonFormField<String>(
                key: ValueKey('categoria_$_tipoSeleccionado'),
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(_iconoSeleccionado, color: colorActivo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _categoriasActuales.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['nombre'] as String,
                    child: Row(
                      children: [
                        Icon(cat['icono'] as IconData, size: 20, color: ColoresApp.textoSecundario),
                        const SizedBox(width: 10),
                        Text(cat['nombre'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (nuevaCategoria) {
                  if (nuevaCategoria != null) {
                    setState(() {
                      _categoriaSeleccionada = nuevaCategoria;
                      final encontrada = _categoriasActuales.firstWhere(
                        (elem) => elem['nombre'] == nuevaCategoria,
                        orElse: () => {'icono': Icons.category_rounded},
                      );
                      _iconoSeleccionado = encontrada['icono'] as IconData;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Sección condicional para Cobro de Deuda o Pago a Acreedor
              if (esCobroDeuda || esAbonoDeuda) ...[
                if (opcionesDeudas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            esCobroDeuda
                                ? 'No tienes personas con deudas pendientes registradas.'
                                : 'No tienes tarjetas o préstamos por pagar registrados.',
                            style: const TextStyle(fontSize: 13, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _deudaSeleccionadaId,
                    decoration: InputDecoration(
                      labelText: esCobroDeuda ? '¿Quién te paga?' : '¿Qué tarjeta o deuda abonas?',
                      prefixIcon: Icon(
                        esCobroDeuda ? Icons.person_rounded : Icons.credit_card_rounded,
                        color: colorActivo,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      helperText: 'Se descontará automáticamente del saldo adeudado.',
                    ),
                    items: opcionesDeudas.map((deuda) {
                      final tipoEtiqueta = deuda.tipoDeuda == TipoDeuda.tarjetaCredito
                          ? 'Tarjeta'
                          : (deuda.tipoDeuda == TipoDeuda.meDeben ? 'Deudor' : 'Acreedor');
                      return DropdownMenuItem<String>(
                        value: deuda.id,
                        child: Text(
                          '[$tipoEtiqueta] ${deuda.tituloOEntidad} (\$${deuda.montoPendiente.toStringAsFixed(2)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (nuevaDeudaId) {
                      setState(() {
                        _deudaSeleccionadaId = nuevaDeudaId;
                        if (_conceptoControlador.text.isEmpty && nuevaDeudaId != null) {
                          final deuda = opcionesDeudas.firstWhere((d) => d.id == nuevaDeudaId);
                          _conceptoControlador.text = esCobroDeuda
                              ? 'Abono de ${deuda.tituloOEntidad}'
                              : 'Pago a ${deuda.tituloOEntidad}';
                        }
                      });
                    },
                    validator: (valor) {
                      if (valor == null) {
                        return 'Selecciona la deuda o tarjeta';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
              ],

              // Botón de Selector de Fecha
              OutlinedButton.icon(
                onPressed: _abrirSelectorFecha,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  'Fecha: ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              FilledButton(
                onPressed: _guardarFormulario,
                style: FilledButton.styleFrom(
                  backgroundColor: colorActivo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Guardar Movimiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
