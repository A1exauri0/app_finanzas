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
import '../../modelos/gasto_fijo_modelo.dart';
import '../../modelos/deuda_modelo.dart';

// ==========================================
// COMPONENTE MODAL: NUEVO O EDITAR GASTO FIJO / SUSCRIPCION
// ==========================================
class NuevoGastoFijoModal extends StatefulWidget {
  final GastoFijoModelo? gastoFijoParaEditar;
  final List<DeudaModelo> listaTarjetas;
  final Function(GastoFijoModelo) alGuardarGastoFijo;

  const NuevoGastoFijoModal({
    super.key,
    this.gastoFijoParaEditar,
    this.listaTarjetas = const [],
    required this.alGuardarGastoFijo,
  });

  @override
  State<NuevoGastoFijoModal> createState() => _NuevoGastoFijoModalState();
}

class _NuevoGastoFijoModalState extends State<NuevoGastoFijoModal> {
  final _formularioClave = GlobalKey<FormState>();

  late TextEditingController _nombreControlador;
  late TextEditingController _montoControlador;
  late int _diaPagoSeleccionado;

  // Catálogo de categorías para gastos fijos con icono y color
  static const List<Map<String, dynamic>> _categoriasDisponibles = [
    {
      'nombre': 'Suscripciones / Streaming',
      'icono': Icons.subscriptions_rounded,
      'color': Color(0xFF1E88E5),
    },
    {
      'nombre': 'Servicios del Hogar',
      'icono': Icons.home_repair_service_rounded,
      'color': Color(0xFFFB8C00),
    },
    {
      'nombre': 'Cuidado Personal / Estilo',
      'icono': Icons.content_cut_rounded,
      'color': Color(0xFF8E24AA),
    },
    {
      'nombre': 'Gimnasio / Deporte',
      'icono': Icons.fitness_center_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'nombre': 'Educación / Cursos',
      'icono': Icons.school_rounded,
      'color': Color(0xFF00897B),
    },
    {
      'nombre': 'Transporte / Seguro',
      'icono': Icons.directions_car_rounded,
      'color': Color(0xFF3949AB),
    },
    {
      'nombre': 'Otro Gasto Fijo',
      'icono': Icons.receipt_long_rounded,
      'color': Color(0xFF546E7A),
    },
  ];

  // Sugerencias rápidas populares
  static const List<Map<String, dynamic>> _sugerenciasPopulares = [
    {'nombre': 'Spotify', 'monto': '129', 'categoria': 'Suscripciones / Streaming', 'dia': 5},
    {'nombre': 'Meli+', 'monto': '149', 'categoria': 'Suscripciones / Streaming', 'dia': 10},
    {'nombre': 'Netflix', 'monto': '219', 'categoria': 'Suscripciones / Streaming', 'dia': 15},
    {'nombre': 'Corte de Cabello', 'monto': '150', 'categoria': 'Cuidado Personal / Estilo', 'dia': 1},
    {'nombre': 'Internet Hogar', 'monto': '550', 'categoria': 'Servicios del Hogar', 'dia': 18},
    {'nombre': 'Gimnasio', 'monto': '450', 'categoria': 'Gimnasio / Deporte', 'dia': 1},
  ];

  late String _categoriaSeleccionada;
  late IconData _iconoSeleccionado;
  late Color _colorSeleccionado;

  bool _pagarConTarjeta = false;
  String? _tarjetaSeleccionadaId;

  bool get _esModoEdicion => widget.gastoFijoParaEditar != null;

  List<DeudaModelo> get _tarjetasCreditoDisponibles => widget.listaTarjetas
      .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
      .toList();

  @override
  void initState() {
    super.initState();
    final actual = widget.gastoFijoParaEditar;

    _nombreControlador = TextEditingController(text: actual?.nombre ?? '');
    _montoControlador = TextEditingController(
      text: actual != null ? actual.monto.toStringAsFixed(2) : '',
    );
    _diaPagoSeleccionado = actual?.diaPago ?? 1;

    if (actual != null) {
      _categoriaSeleccionada = actual.categoria;
      _iconoSeleccionado = actual.icono;
      _colorSeleccionado = actual.color;
      _pagarConTarjeta = actual.pagarConTarjeta;
      _tarjetaSeleccionadaId = actual.idTarjeta;
    } else {
      _categoriaSeleccionada = _categoriasDisponibles.first['nombre'] as String;
      _iconoSeleccionado = _categoriasDisponibles.first['icono'] as IconData;
      _colorSeleccionado = _categoriasDisponibles.first['color'] as Color;

      if (_tarjetasCreditoDisponibles.isNotEmpty) {
        _tarjetaSeleccionadaId = _tarjetasCreditoDisponibles.first.id;
      }
    }
  }

  @override
  void dispose() {
    _nombreControlador.dispose();
    _montoControlador.dispose();
    super.dispose();
  }

  // Aplicar sugerencia rápida
  void _aplicarSugerencia(Map<String, dynamic> sugerencia) {
    setState(() {
      _nombreControlador.text = sugerencia['nombre'] as String;
      _montoControlador.text = sugerencia['monto'] as String;
      _diaPagoSeleccionado = sugerencia['dia'] as int;

      final catMatch = _categoriasDisponibles.firstWhere(
        (c) => c['nombre'] == sugerencia['categoria'],
        orElse: () => _categoriasDisponibles.first,
      );
      _categoriaSeleccionada = catMatch['nombre'] as String;
      _iconoSeleccionado = catMatch['icono'] as IconData;
      _colorSeleccionado = catMatch['color'] as Color;
    });
  }

  void _guardar() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double monto = double.parse(_montoControlador.text.replaceAll(',', ''));

      String? nombreTarjeta;
      if (_pagarConTarjeta && _tarjetaSeleccionadaId != null) {
        final tarjetaMatch = _tarjetasCreditoDisponibles.firstWhere(
          (t) => t.id == _tarjetaSeleccionadaId,
          orElse: () => _tarjetasCreditoDisponibles.first,
        );
        nombreTarjeta = tarjetaMatch.tituloOEntidad;
      }

      final nuevoGastoFijo = GastoFijoModelo(
        id: widget.gastoFijoParaEditar?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreControlador.text.trim(),
        monto: monto,
        diaPago: _diaPagoSeleccionado,
        categoria: _categoriaSeleccionada,
        icono: _iconoSeleccionado,
        color: _colorSeleccionado,
        pagarConTarjeta: _pagarConTarjeta && _tarjetasCreditoDisponibles.isNotEmpty,
        idTarjeta: _pagarConTarjeta ? _tarjetaSeleccionadaId : null,
        nombreTarjeta: _pagarConTarjeta ? nombreTarjeta : null,
        ultimoMesPagado: widget.gastoFijoParaEditar?.ultimoMesPagado,
      );

      widget.alGuardarGastoFijo(nuevoGastoFijo);
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
              // Barra indicadora
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

              // Título del modal
              Text(
                _esModoEdicion ? 'Editar Gasto Fijo / Suscripción' : 'Nuevo Gasto Fijo o Mensual',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.texto(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Chips de sugerencias rápidas (solo en modo creación)
              if (!_esModoEdicion) ...[
                Text(
                  'Sugerencias rápidas:',
                  style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sugerenciasPopulares.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.flash_on_rounded, size: 14),
                          label: Text('${s['nombre']} (\$${s['monto']})'),
                          onPressed: () => _aplicarSugerencia(s),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo de Nombre / Servicio
              TextFormField(
                controller: _nombreControlador,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio o Gasto',
                  hintText: 'Ej. Spotify, Meli+, Corte de cabello',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el nombre del gasto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo de Monto
              TextFormField(
                controller: _montoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar mensual (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final parsed = double.tryParse(valor.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Selector de Día de Pago del Mes (1 a 31)
              DropdownButtonFormField<int>(
                initialValue: _diaPagoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Día de cobro o pago en el mes',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(31, (index) => index + 1).map((dia) {
                  return DropdownMenuItem<int>(
                    value: dia,
                    child: Text('Día $dia de cada mes'),
                  );
                }).toList(),
                onChanged: (nuevoDia) {
                  if (nuevoDia != null) {
                    setState(() => _diaPagoSeleccionado = nuevoDia);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Selector de Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_rounded),
                  border: OutlineInputBorder(),
                ),
                items: _categoriasDisponibles.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['nombre'] as String,
                    child: Row(
                      children: [
                        Icon(cat['icono'] as IconData, size: 20, color: cat['color'] as Color),
                        const SizedBox(width: 10),
                        Text(cat['nombre'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (nuevaCat) {
                  if (nuevaCat != null) {
                    final item = _categoriasDisponibles.firstWhere((c) => c['nombre'] == nuevaCat);
                    setState(() {
                      _categoriaSeleccionada = item['nombre'] as String;
                      _iconoSeleccionado = item['icono'] as IconData;
                      _colorSeleccionado = item['color'] as Color;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Método de pago: Efectivo o Tarjeta de crédito
              if (_tarjetasCreditoDisponibles.isNotEmpty) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Domiciliar o pagar con Tarjeta de Crédito'),
                  subtitle: Text(
                    _pagarConTarjeta
                        ? 'Se cargará a la tarjeta seleccionada'
                        : 'Se pagará con efectivo / débito',
                    style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                  ),
                  value: _pagarConTarjeta,
                  activeThumbColor: ColoresApp.primarioVerde,
                  onChanged: (val) => setState(() => _pagarConTarjeta = val),
                ),
                if (_pagarConTarjeta) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _tarjetaSeleccionadaId ?? _tarjetasCreditoDisponibles.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Selecciona la Tarjeta de Crédito',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: _tarjetasCreditoDisponibles.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.tituloOEntidad),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _tarjetaSeleccionadaId = val);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 14),
              ],

              // Botón Guardar
              FilledButton(
                onPressed: _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: _colorSeleccionado,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _esModoEdicion ? 'Guardar Cambios' : 'Registrar Gasto Fijo',
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
