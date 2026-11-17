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

// ==========================================
// COMPONENTE VISUAL: MODAL PARA EDITAR MOVIMIENTO
// ==========================================
class EditarMovimientoModal extends StatefulWidget {
  final MovimientoModelo movimientoOriginal;
  final Function(MovimientoModelo) alGuardarCambios;

  const EditarMovimientoModal({
    super.key,
    required this.movimientoOriginal,
    required this.alGuardarCambios,
  });

  @override
  State<EditarMovimientoModal> createState() => _EditarMovimientoModalState();
}

class _EditarMovimientoModalState extends State<EditarMovimientoModal> {
  // Clave global para validación
  final _formularioClave = GlobalKey<FormState>();

  // Controladores de formulario
  late TextEditingController _conceptoControlador;
  late TextEditingController _montoControlador;

  // Estados locales editables
  late DateTime _fechaSeleccionada;
  late String _categoriaSeleccionada;
  late IconData _iconoSeleccionado;

  // Categorías de Ingresos
  static const List<Map<String, dynamic>> _categoriasIngreso = [
    {'nombre': 'Sueldo', 'icono': Icons.account_balance_wallet_rounded},
    {'nombre': 'Cobro de Deuda', 'icono': Icons.handshake_rounded},
    {'nombre': 'Ingreso Extra', 'icono': Icons.monetization_on_rounded},
    {'nombre': 'Ventas', 'icono': Icons.storefront_rounded},
    {'nombre': 'Otro Ingreso', 'icono': Icons.add_circle_outline_rounded},
  ];

  // Categorías de Gastos
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

  List<Map<String, dynamic>> get _catalogoCategorias =>
      widget.movimientoOriginal.tipo == TipoMovimiento.ingreso
          ? _categoriasIngreso
          : _categoriasGasto;

  @override
  void initState() {
    super.initState();
    _conceptoControlador = TextEditingController(text: widget.movimientoOriginal.titulo);
    _montoControlador = TextEditingController(text: widget.movimientoOriginal.monto.toStringAsFixed(2));
    _fechaSeleccionada = widget.movimientoOriginal.fecha;
    _categoriaSeleccionada = widget.movimientoOriginal.categoria;
    _iconoSeleccionado = widget.movimientoOriginal.icono;
  }

  @override
  void dispose() {
    _conceptoControlador.dispose();
    _montoControlador.dispose();
    super.dispose();
  }

  // Selector de fecha
  Future<void> _abrirSelectorFecha() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fechaElegida != null) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
    }
  }

  // Guardar edición
  void _guardarCambios() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double? monto = double.tryParse(_montoControlador.text.replaceAll(',', ''));
      if (monto == null || monto <= 0) return;

      final movimientoActualizado = MovimientoModelo(
        id: widget.movimientoOriginal.id,
        titulo: _conceptoControlador.text.trim(),
        monto: monto,
        fecha: _fechaSeleccionada,
        tipo: widget.movimientoOriginal.tipo,
        icono: widget.movimientoOriginal.pagadoConTarjeta
            ? Icons.credit_card_rounded
            : _iconoSeleccionado,
        categoria: _categoriaSeleccionada,
        idDeudaAsociada: widget.movimientoOriginal.idDeudaAsociada,
        nombreDeudorAsociado: widget.movimientoOriginal.nombreDeudorAsociado,
        pagadoConTarjeta: widget.movimientoOriginal.pagadoConTarjeta,
        idTarjetaUtilizada: widget.movimientoOriginal.idTarjetaUtilizada,
        nombreTarjetaUtilizada: widget.movimientoOriginal.nombreTarjetaUtilizada,
      );

      widget.alGuardarCambios(movimientoActualizado);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esIngreso = widget.movimientoOriginal.tipo == TipoMovimiento.ingreso;
    final Color colorTema = esIngreso ? ColoresApp.ingresoVerde : ColoresApp.gastoRojo;

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
              // Barra indicadora de arrastre
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

              // Encabezado
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorTema.withValues(alpha: 0.12),
                    child: Icon(Icons.edit_rounded, color: colorTema),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Movimiento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.textoPrincipal,
                          ),
                        ),
                        Text(
                          esIngreso ? 'Ingreso registrado' : 'Gasto registrado',
                          style: TextStyle(fontSize: 13, color: colorTema, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Campo de Monto
              TextFormField(
                controller: _montoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Monto (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded, color: colorTema),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorTema, width: 2),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) return 'Ingresa un monto';
                  final m = double.tryParse(valor.replaceAll(',', ''));
                  if (m == null || m <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Concepto
              TextFormField(
                controller: _conceptoControlador,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Concepto o Descripción',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) return 'Ingresa un concepto';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(_iconoSeleccionado, color: colorTema),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _catalogoCategorias.map((cat) {
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
                      final encontrada = _catalogoCategorias.firstWhere(
                        (c) => c['nombre'] == nuevaCategoria,
                        orElse: () => {'icono': Icons.category_rounded},
                      );
                      _iconoSeleccionado = encontrada['icono'] as IconData;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Selector de Fecha
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

              // Botón Guardar Cambios
              FilledButton(
                onPressed: _guardarCambios,
                style: FilledButton.styleFrom(
                  backgroundColor: colorTema,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Actualizar Movimiento',
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
