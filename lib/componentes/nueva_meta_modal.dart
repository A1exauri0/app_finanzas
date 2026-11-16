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
import '../modelos/meta_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: MODAL PARA CREAR O EDITAR META
// ==========================================
class NuevaMetaModal extends StatefulWidget {
  final MetaModelo? metaParaEditar;
  final Function(MetaModelo) alGuardarMeta;

  const NuevaMetaModal({
    super.key,
    this.metaParaEditar,
    required this.alGuardarMeta,
  });

  @override
  State<NuevaMetaModal> createState() => _NuevaMetaModalState();
}

class _NuevaMetaModalState extends State<NuevaMetaModal> {
  final _formularioClave = GlobalKey<FormState>();

  late TextEditingController _tituloControlador;
  late TextEditingController _montoObjetivoControlador;
  late TextEditingController _montoAhorradoControlador;
  late TextEditingController _notasControlador;

  DateTime? _fechaObjetivoSeleccionada;

  // Categorías de metas predefinidas con icono y color
  final List<Map<String, dynamic>> _categoriasMeta = [
    {'nombre': 'Gimnasio / Fitness', 'icono': Icons.fitness_center_rounded, 'color': const Color(0xFFD32F2F)},
    {'nombre': 'Tecnología', 'icono': Icons.devices_rounded, 'color': const Color(0xFF1976D2)},
    {'nombre': 'Viajes', 'icono': Icons.flight_takeoff_rounded, 'color': const Color(0xFF0097A7)},
    {'nombre': 'Vehículo', 'icono': Icons.directions_car_rounded, 'color': const Color(0xFFE65100)},
    {'nombre': 'Hogar / Muebles', 'icono': Icons.home_rounded, 'color': const Color(0xFF5D4037)},
    {'nombre': 'Fondo de Emergencia', 'icono': Icons.shield_rounded, 'color': const Color(0xFF2E7D32)},
    {'nombre': 'Educación', 'icono': Icons.school_rounded, 'color': const Color(0xFF6A1B9A)},
    {'nombre': 'Moda / Ropa', 'icono': Icons.checkroom_rounded, 'color': const Color(0xFFC2185B)},
    {'nombre': 'Otro Objetivo', 'icono': Icons.flag_rounded, 'color': const Color(0xFF455A64)},
  ];

  late String _categoriaSeleccionada;
  late IconData _iconoSeleccionado;
  late Color _colorSeleccionado;

  bool get _esModoEdicion => widget.metaParaEditar != null;

  @override
  void initState() {
    super.initState();
    final meta = widget.metaParaEditar;

    _tituloControlador = TextEditingController(text: meta?.titulo ?? '');
    _montoObjetivoControlador = TextEditingController(
      text: meta != null ? meta.montoObjetivo.toStringAsFixed(2) : '',
    );
    _montoAhorradoControlador = TextEditingController(
      text: meta != null ? meta.montoAhorrado.toStringAsFixed(2) : '',
    );
    _notasControlador = TextEditingController(text: meta?.notas ?? '');
    _fechaObjetivoSeleccionada = meta?.fechaObjetivo;

    if (meta != null) {
      _categoriaSeleccionada = meta.categoria;
      _iconoSeleccionado = meta.icono;
      _colorSeleccionado = meta.color;
    } else {
      _categoriaSeleccionada = _categoriasMeta.first['nombre'] as String;
      _iconoSeleccionado = _categoriasMeta.first['icono'] as IconData;
      _colorSeleccionado = _categoriasMeta.first['color'] as Color;
    }
  }

  @override
  void dispose() {
    _tituloControlador.dispose();
    _montoObjetivoControlador.dispose();
    _montoAhorradoControlador.dispose();
    _notasControlador.dispose();
    super.dispose();
  }

  // Selector de fecha objetivo con DatePicker
  Future<void> _abrirSelectorFecha() async {
    final DateTime ahora = DateTime.now();
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      helpText: 'FECHA DESEADA PARA CUMPLIR LA META',
      initialDate: _fechaObjetivoSeleccionada ?? ahora.add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (fechaElegida != null) {
      setState(() {
        _fechaObjetivoSeleccionada = fechaElegida;
      });
    }
  }

  // Guardar meta (crear nueva o actualizar existente)
  void _guardarMeta() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double objetivo = double.parse(_montoObjetivoControlador.text.replaceAll(',', ''));
      final double ahorrado = _montoAhorradoControlador.text.trim().isNotEmpty
          ? double.parse(_montoAhorradoControlador.text.replaceAll(',', ''))
          : 0.0;

      final metaResultado = MetaModelo(
        id: widget.metaParaEditar?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _tituloControlador.text.trim(),
        montoObjetivo: objetivo,
        montoAhorrado: ahorrado,
        fechaObjetivo: _fechaObjetivoSeleccionada,
        categoria: _categoriaSeleccionada,
        icono: _iconoSeleccionado,
        color: _colorSeleccionado,
        notas: _notasControlador.text.trim().isEmpty ? null : _notasControlador.text.trim(),
      );

      widget.alGuardarMeta(metaResultado);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Barra de arrastre
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

              Text(
                _esModoEdicion ? 'Editar Meta de Compra' : 'Nueva Meta de Compra o Ahorro',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoPrincipal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Selector de Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría del Objetivo',
                  prefixIcon: Icon(_iconoSeleccionado, color: _colorSeleccionado),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _categoriasMeta.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['nombre'] as String,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: (cat['color'] as Color).withValues(alpha: 0.15),
                          child: Icon(cat['icono'] as IconData, size: 16, color: cat['color'] as Color),
                        ),
                        const SizedBox(width: 12),
                        Text(cat['nombre'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (nuevaCat) {
                  if (nuevaCat != null) {
                    setState(() {
                      _categoriaSeleccionada = nuevaCat;
                      final encontrada = _categoriasMeta.firstWhere(
                        (c) => c['nombre'] == nuevaCat,
                        orElse: () => _categoriasMeta.last,
                      );
                      _iconoSeleccionado = encontrada['icono'] as IconData;
                      _colorSeleccionado = encontrada['color'] as Color;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Nombre / Título de la meta
              TextFormField(
                controller: _tituloControlador,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '¿Qué deseas comprar o lograr?',
                  hintText: 'Ej. Membresía Smart Fit, MacBook, Enganche',
                  prefixIcon: Icon(Icons.stars_rounded, color: _colorSeleccionado),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el nombre de tu meta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monto Objetivo
              TextFormField(
                controller: _montoObjetivoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Monto Objetivo Total (\$)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el monto objetivo';
                  }
                  final monto = double.tryParse(valor.replaceAll(',', ''));
                  if (monto == null || monto <= 0) {
                    return 'Ingresa un número positivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monto Ahorrado
              TextFormField(
                controller: _montoAhorradoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _esModoEdicion ? 'Monto Ahorrado Actual (\$)' : 'Ahorro Inicial (Opcional) (\$)',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  helperText: 'Ahorro acumulado para esta meta.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Fecha Objetivo con DatePicker
              OutlinedButton.icon(
                onPressed: _abrirSelectorFecha,
                icon: const Icon(Icons.event_available_rounded),
                label: Text(
                  _fechaObjetivoSeleccionada == null
                      ? 'Fecha Deseada para Cumplirla (Opcional)'
                      : 'Fecha Deseada: ${_fechaObjetivoSeleccionada!.day}/${_fechaObjetivoSeleccionada!.month}/${_fechaObjetivoSeleccionada!.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Notas o detalles
              TextFormField(
                controller: _notasControlador,
                decoration: InputDecoration(
                  labelText: 'Notas o Enlace del producto (Opcional)',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              FilledButton(
                onPressed: _guardarMeta,
                style: FilledButton.styleFrom(
                  backgroundColor: _colorSeleccionado,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _esModoEdicion ? 'Guardar Cambios de la Meta' : 'Crear Meta de Compra',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
