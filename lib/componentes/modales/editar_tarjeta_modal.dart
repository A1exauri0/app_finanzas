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
import '../../modelos/deuda_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: MODAL PARA EDITAR TARJETA DE CRÉDITO
// ==========================================
class EditarTarjetaModal extends StatefulWidget {
  final DeudaModelo tarjeta;
  final Function(DeudaModelo) alGuardarCambios;

  const EditarTarjetaModal({
    super.key,
    required this.tarjeta,
    required this.alGuardarCambios,
  });

  @override
  State<EditarTarjetaModal> createState() => _EditarTarjetaModalState();
}

class _EditarTarjetaModalState extends State<EditarTarjetaModal> {
  final _formularioClave = GlobalKey<FormState>();

  late TextEditingController _nombreControlador;
  late TextEditingController _limiteTotalControlador;
  late TextEditingController _limiteAjustadoControlador;
  late TextEditingController _saldoPendienteControlador;

  int? _diaCorte;
  DateTime? _fechaLimitePago;

  @override
  void initState() {
    super.initState();
    _nombreControlador = TextEditingController(text: widget.tarjeta.tituloOEntidad);
    _limiteTotalControlador = TextEditingController(text: widget.tarjeta.montoTotal.toStringAsFixed(2));
    _limiteAjustadoControlador = TextEditingController(
      text: widget.tarjeta.limiteAjustado != null ? widget.tarjeta.limiteAjustado!.toStringAsFixed(2) : '',
    );
    _saldoPendienteControlador = TextEditingController(text: widget.tarjeta.montoPendiente.toStringAsFixed(2));
    _diaCorte = widget.tarjeta.diaCorte;
    _fechaLimitePago = widget.tarjeta.fechaLimitePago;
  }

  @override
  void dispose() {
    _nombreControlador.dispose();
    _limiteTotalControlador.dispose();
    _limiteAjustadoControlador.dispose();
    _saldoPendienteControlador.dispose();
    super.dispose();
  }

  // Selector de calendario para el día de corte
  Future<void> _abrirSelectorCorte() async {
    final DateTime ahora = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      helpText: 'DÍA DE CORTE DE ${widget.tarjeta.tituloOEntidad.toUpperCase()}',
      initialDate: DateTime(ahora.year, ahora.month, _diaCorte ?? 15),
      firstDate: DateTime(ahora.year, ahora.month, 1),
      lastDate: DateTime(ahora.year, ahora.month, 31),
    );

    if (fecha != null) {
      setState(() {
        _diaCorte = fecha.day;
      });
    }
  }

  // Selector de fecha límite de pago
  Future<void> _abrirSelectorFechaLimite() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimitePago ?? DateTime.now().add(const Duration(days: 20)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (fecha != null) {
      setState(() {
        _fechaLimitePago = fecha;
      });
    }
  }

  // Guardar cambios
  void _guardarEdicion() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double total = double.parse(_limiteTotalControlador.text.replaceAll(',', ''));
      final double? limiteAjustado = _limiteAjustadoControlador.text.trim().isNotEmpty
          ? double.tryParse(_limiteAjustadoControlador.text.replaceAll(',', ''))
          : null;
      final double saldoPendiente = double.parse(_saldoPendienteControlador.text.replaceAll(',', ''));

      final tarjetaActualizada = DeudaModelo(
        id: widget.tarjeta.id,
        tituloOEntidad: _nombreControlador.text.trim(),
        tipoDeuda: TipoDeuda.tarjetaCredito,
        montoTotal: total,
        limiteAjustado: limiteAjustado,
        montoPendiente: saldoPendiente,
        fechaLimitePago: _fechaLimitePago,
        diaCorte: _diaCorte,
        colorTarjeta: widget.tarjeta.colorTarjeta,
        notas: widget.tarjeta.notas,
        historialPartidas: widget.tarjeta.historialPartidas,
      );

      widget.alGuardarCambios(tarjetaActualizada);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color colorMarca = widget.tarjeta.colorTarjeta ?? ColoresApp.primarioVerde;

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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 12, backgroundColor: colorMarca),
                  const SizedBox(width: 8),
                  Text(
                    'Editar ${widget.tarjeta.tituloOEntidad}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.textoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nombre / Alias
              TextFormField(
                controller: _nombreControlador,
                decoration: InputDecoration(
                  labelText: 'Nombre o Alias de la Tarjeta',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 14),

              // Límite Total del Banco
              TextFormField(
                controller: _limiteTotalControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Límite Total Otorgado por el Banco (\$)',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                  helperText: 'Límite de crédito real según tu estado de cuenta.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '')) == null)
                    ? 'Monto inválido'
                    : null,
              ),
              const SizedBox(height: 14),

              // Límite Ajustado de Control Personal (Tope propio)
              TextFormField(
                controller: _limiteAjustadoControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Límite Ajustado de Control Propio (Opcional) (\$)',
                  prefixIcon: const Icon(Icons.tune_rounded),
                  helperText: 'Ejemplo: Tu banco te da \$4,000 pero fijas tu tope en \$2,000.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 14),

              // Saldo Usado / a Pagar
              TextFormField(
                controller: _saldoPendienteControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Saldo Usado a Pagar (\$)',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  helperText: 'Deuda o consumo actual de la tarjeta.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '')) == null)
                    ? 'Monto inválido'
                    : null,
              ),
              const SizedBox(height: 16),

              // Botón Selector de Día de Corte
              OutlinedButton.icon(
                onPressed: _abrirSelectorCorte,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  _diaCorte != null
                      ? 'Día de corte: Día $_diaCorte de cada mes'
                      : 'Asignar día de corte',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Selector de Fecha Límite de Pago
              OutlinedButton.icon(
                onPressed: _abrirSelectorFechaLimite,
                icon: const Icon(Icons.event_available_rounded),
                label: Text(
                  _fechaLimitePago != null
                      ? 'Fecha Límite: ${_fechaLimitePago!.day}/${_fechaLimitePago!.month}/${_fechaLimitePago!.year}'
                      : 'Asignar Fecha Límite de Pago',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 22),

              // Botón Guardar
              FilledButton(
                onPressed: _guardarEdicion,
                style: FilledButton.styleFrom(
                  backgroundColor: colorMarca,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Guardar Cambios de la Tarjeta',
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
