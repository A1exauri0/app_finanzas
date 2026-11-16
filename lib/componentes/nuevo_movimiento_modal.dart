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

// ==========================================
// COMPONENTE VISUAL: MODAL PARA NUEVO MOVIMIENTO
// ==========================================
class NuevoMovimientoModal extends StatefulWidget {
  final TipoMovimiento tipoInicial;
  final Function(MovimientoModelo) alGuardarMovimiento;

  const NuevoMovimientoModal({
    super.key,
    required this.tipoInicial,
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
  String _categoriaSeleccionada = 'General';
  IconData _iconoSeleccionado = Icons.attach_money_rounded;

  // Lista de categorías disponibles según el tipo
  final List<Map<String, dynamic>> _categoriasDisponibles = [
    {'nombre': 'Sueldo', 'icono': Icons.account_balance_wallet_rounded},
    {'nombre': 'Alimentación', 'icono': Icons.shopping_cart_rounded},
    {'nombre': 'Transporte', 'icono': Icons.directions_bus_rounded},
    {'nombre': 'Servicios', 'icono': Icons.wifi_rounded},
    {'nombre': 'Entretenimiento', 'icono': Icons.movie_rounded},
    {'nombre': 'Salud', 'icono': Icons.medical_services_rounded},
    {'nombre': 'General', 'icono': Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.tipoInicial;
    _fechaSeleccionada = DateTime.now();
  }

  @override
  void dispose() {
    _montoControlador.dispose();
    _conceptoControlador.dispose();
    super.dispose();
  }

  // Método para guardar y emitir el nuevo movimiento
  void _guardarFormulario() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double? monto = double.tryParse(_montoControlador.text.replaceAll(',', ''));
      if (monto == null || monto <= 0) return;

      final nuevoMovimiento = MovimientoModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _conceptoControlador.text.trim(),
        monto: monto,
        fecha: _fechaSeleccionada,
        tipo: _tipoSeleccionado,
        icono: _iconoSeleccionado,
        categoria: _categoriaSeleccionada,
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
                  setState(() {
                    _tipoSeleccionado = nuevaSeleccion.first;
                  });
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
                  if (double.tryParse(valor.replaceAll(',', '')) == null) {
                    return 'Formato numérico incorrecto';
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

              // Selector de Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(_iconoSeleccionado, color: colorActivo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _categoriasDisponibles.map((cat) {
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
                      final encontrada = _categoriasDisponibles.firstWhere(
                        (elem) => elem['nombre'] == nuevaCategoria,
                        orElse: () => {'icono': Icons.category_rounded},
                      );
                      _iconoSeleccionado = encontrada['icono'] as IconData;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

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
