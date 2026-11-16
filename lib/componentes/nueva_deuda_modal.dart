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
// COMPONENTE VISUAL: MODAL PARA CREAR DEUDA O TARJETA
// ==========================================
class NuevaDeudaModal extends StatefulWidget {
  final Function(DeudaModelo) alGuardarDeuda;

  const NuevaDeudaModal({
    super.key,
    required this.alGuardarDeuda,
  });

  @override
  State<NuevaDeudaModal> createState() => _NuevaDeudaModalState();
}

class _NuevaDeudaModalState extends State<NuevaDeudaModal> {
  // Clave del formulario
  final _formularioClave = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _tituloControlador = TextEditingController();
  final TextEditingController _montoTotalControlador = TextEditingController();
  final TextEditingController _montoPendienteControlador = TextEditingController();
  final TextEditingController _diaCorteControlador = TextEditingController();
  final TextEditingController _notasControlador = TextEditingController();

  // Estados locales
  TipoDeuda _tipoDeudaSeleccionada = TipoDeuda.meDeben;
  DateTime? _fechaLimiteSeleccionada;

  @override
  void dispose() {
    _tituloControlador.dispose();
    _montoTotalControlador.dispose();
    _montoPendienteControlador.dispose();
    _diaCorteControlador.dispose();
    _notasControlador.dispose();
    super.dispose();
  }

  // Guardar la deuda
  void _guardarDeuda() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double total = double.parse(_montoTotalControlador.text.replaceAll(',', ''));
      final double pendiente = _montoPendienteControlador.text.isEmpty
          ? total
          : double.parse(_montoPendienteControlador.text.replaceAll(',', ''));

      final int? diaCorte = _tipoDeudaSeleccionada == TipoDeuda.tarjetaCredito
          ? int.tryParse(_diaCorteControlador.text)
          : null;

      final nuevaDeuda = DeudaModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tituloOEntidad: _tituloControlador.text.trim(),
        tipoDeuda: _tipoDeudaSeleccionada,
        montoTotal: total,
        montoPendiente: pendiente,
        fechaLimitePago: _fechaLimiteSeleccionada,
        diaCorte: diaCorte,
        notas: _notasControlador.text.trim().isEmpty ? null : _notasControlador.text.trim(),
      );

      widget.alGuardarDeuda(nuevaDeuda);
      Navigator.of(context).pop();
    }
  }

  // Selector de fecha límite
  Future<void> _abrirSelectorFechaLimite() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimiteSeleccionada ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (fechaElegida != null) {
      setState(() {
        _fechaLimiteSeleccionada = fechaElegida;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esTarjeta = _tipoDeudaSeleccionada == TipoDeuda.tarjetaCredito;
    final bool esMeDeben = _tipoDeudaSeleccionada == TipoDeuda.meDeben;

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
              // Indicador superior
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

              // Título
              const Text(
                'Registrar Deuda o Tarjeta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.textoPrincipal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Selector del tipo de deuda
              SegmentedButton<TipoDeuda>(
                segments: const [
                  ButtonSegment(
                    value: TipoDeuda.meDeben,
                    label: Text('Me Deben'),
                    icon: Icon(Icons.handshake_rounded),
                  ),
                  ButtonSegment(
                    value: TipoDeuda.debo,
                    label: Text('Debo'),
                    icon: Icon(Icons.money_off_csred_rounded),
                  ),
                  ButtonSegment(
                    value: TipoDeuda.tarjetaCredito,
                    label: Text('Tarjeta'),
                    icon: Icon(Icons.credit_card_rounded),
                  ),
                ],
                selected: {_tipoDeudaSeleccionada},
                onSelectionChanged: (nuevaSeleccion) {
                  setState(() {
                    _tipoDeudaSeleccionada = nuevaSeleccion.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Nombre / Entidad
              TextFormField(
                controller: _tituloControlador,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: esTarjeta
                      ? 'Nombre del Banco / Tarjeta (ej. BBVA Oro)'
                      : (esMeDeben ? 'Nombre de la persona (ej. Juan Pérez)' : 'A quién le debes (ej. Préstamo Amigo)'),
                  prefixIcon: Icon(esTarjeta ? Icons.credit_card_rounded : Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) =>
                    (valor == null || valor.trim().isEmpty) ? 'Ingresa un nombre o entidad' : null,
              ),
              const SizedBox(height: 16),

              // Monto Total / Límite
              TextFormField(
                controller: _montoTotalControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: esTarjeta ? 'Límite de Crédito (\$)' : 'Monto Total Prestado / Deuda (\$)',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(valor.replaceAll(',', '')) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monto Pendiente (Saldo actual adeudado)
              TextFormField(
                controller: _montoPendienteControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: esTarjeta ? 'Saldo Usado a Pagar (\$)' : 'Saldo Pendiente Actual (\$)',
                  helperText: 'Si es la deuda completa, déjalo igual o vacío.',
                  prefixIcon: const Icon(Icons.pending_actions_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Campos específicos para Tarjeta de Crédito
              if (esTarjeta) ...[
                TextFormField(
                  controller: _diaCorteControlador,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Día del mes de corte (1 al 31)',
                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Selector de Fecha límite de pago
              OutlinedButton.icon(
                onPressed: _abrirSelectorFechaLimite,
                icon: const Icon(Icons.event_available_rounded),
                label: Text(
                  _fechaLimiteSeleccionada == null
                      ? 'Asignar Fecha Límite de Pago (Opcional)'
                      : 'Fecha Límite: ${_fechaLimiteSeleccionada!.day}/${_fechaLimiteSeleccionada!.month}/${_fechaLimiteSeleccionada!.year}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              FilledButton(
                onPressed: _guardarDeuda,
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.primarioVerde,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Guardar Deuda / Tarjeta',
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
