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

// ==========================================
// COMPONENTE VISUAL: MODAL PARA NUEVO MOVIMIENTO
// ==========================================
class NuevoMovimientoModal extends StatefulWidget {
  final TipoMovimiento tipoInicial;
  final List<DeudaModelo> listaDeudasActivas;
  final Function(MovimientoModelo) alGuardarMovimiento;

  const NuevoMovimientoModal({
    super.key,
    required this.tipoInicial,
    this.listaDeudasActivas = const [],
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

  // Estado para vincular cobro de deuda
  String? _deudaSeleccionadaId;

  // Categorías exclusivas para Ingresos
  static const List<Map<String, dynamic>> _categoriasIngreso = [
    {'nombre': 'Sueldo', 'icono': Icons.account_balance_wallet_rounded},
    {'nombre': 'Cobro de Deuda', 'icono': Icons.handshake_rounded},
    {'nombre': 'Ingreso Extra', 'icono': Icons.monetization_on_rounded},
    {'nombre': 'Ventas', 'icono': Icons.storefront_rounded},
    {'nombre': 'Inversión', 'icono': Icons.trending_up_rounded},
    {'nombre': 'Otro Ingreso', 'icono': Icons.add_circle_outline_rounded},
  ];

  // Categorías exclusivas para Gastos
  static const List<Map<String, dynamic>> _categoriasGasto = [
    {'nombre': 'Alimentación', 'icono': Icons.shopping_cart_rounded},
    {'nombre': 'Transporte', 'icono': Icons.directions_bus_rounded},
    {'nombre': 'Servicios', 'icono': Icons.wifi_rounded},
    {'nombre': 'Entretenimiento', 'icono': Icons.movie_rounded},
    {'nombre': 'Salud', 'icono': Icons.medical_services_rounded},
    {'nombre': 'Educación', 'icono': Icons.school_rounded},
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

    final categoriasIniciales = _categoriasActuales;
    _categoriaSeleccionada = categoriasIniciales.first['nombre'] as String;
    _iconoSeleccionado = categoriasIniciales.first['icono'] as IconData;
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

      String? nombreDeudor;
      if (_tipoSeleccionado == TipoMovimiento.ingreso &&
          _categoriaSeleccionada == 'Cobro de Deuda' &&
          _deudaSeleccionadaId != null) {
        final deuda = widget.listaDeudasActivas.firstWhere(
          (d) => d.id == _deudaSeleccionadaId,
        );
        nombreDeudor = deuda.nombreDeudor;
      }

      final nuevoMovimiento = MovimientoModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _conceptoControlador.text.trim(),
        monto: monto,
        fecha: _fechaSeleccionada,
        tipo: _tipoSeleccionado,
        icono: _iconoSeleccionado,
        categoria: _categoriaSeleccionada,
        idDeudaAsociada: _deudaSeleccionadaId,
        nombreDeudorAsociado: nombreDeudor,
      );

      widget.alGuardarMovimiento(nuevoMovimiento);
      Navigator.of(context).pop();
    }
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
    final bool esCobroDeuda = esIngreso && _categoriaSeleccionada == 'Cobro de Deuda';

    // Filtramos las deudas que tienen saldo pendiente
    final deudasPendientes = widget.listaDeudasActivas.where((d) => !d.estaSaldada).toList();

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
                    borderSide: BorderSide(color: colorActivo, width: 2),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa un monto válido';
                  }
                  final montoParsed = double.tryParse(valor.replaceAll(',', ''));
                  if (montoParsed == null || montoParsed <= 0) {
                    return 'Ingresa un número positivo mayor a 0';
                  }
                  return null;
                },
              ),
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
                  labelText: 'Categoría de ${esIngreso ? "Ingreso" : "Gasto"}',
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

              // Sección condicional: Si es Cobro de Deuda, seleccionar de qué deudor se descuenta
              if (esCobroDeuda) ...[
                if (deudasPendientes.isEmpty)
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
                            'No tienes personas con deudas pendientes registradas.',
                            style: TextStyle(fontSize: 13, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _deudaSeleccionadaId,
                    decoration: InputDecoration(
                      labelText: '¿Quién te está pagando?',
                      prefixIcon: const Icon(Icons.person_rounded, color: ColoresApp.ingresoVerde),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      helperText: 'El monto ingresado se restará automáticamente de su saldo.',
                    ),
                    items: deudasPendientes.map((deuda) {
                      return DropdownMenuItem<String>(
                        value: deuda.id,
                        child: Text(
                          '${deuda.nombreDeudor} (Debe: \$${deuda.montoPendiente.toStringAsFixed(2)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (nuevaDeudaId) {
                      setState(() {
                        _deudaSeleccionadaId = nuevaDeudaId;
                        if (_conceptoControlador.text.isEmpty && nuevaDeudaId != null) {
                          final deuda = deudasPendientes.firstWhere((d) => d.id == nuevaDeudaId);
                          _conceptoControlador.text = 'Abono de ${deuda.nombreDeudor}';
                        }
                      });
                    },
                    validator: (valor) {
                      if (valor == null) {
                        return 'Selecciona de qué deuda se descontará';
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
