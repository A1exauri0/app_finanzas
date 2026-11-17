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
// COMPONENTE VISUAL: MODAL PARA EDITAR DEUDA PERSONAL
// ==========================================
class EditarDeudaPersonaModal extends StatefulWidget {
  final DeudaModelo deuda;
  final Function(DeudaModelo) alGuardarCambios;

  const EditarDeudaPersonaModal({
    super.key,
    required this.deuda,
    required this.alGuardarCambios,
  });

  @override
  State<EditarDeudaPersonaModal> createState() => _EditarDeudaPersonaModalState();
}

class _EditarDeudaPersonaModalState extends State<EditarDeudaPersonaModal> {
  final _formularioClave = GlobalKey<FormState>();

  late TextEditingController _nombreControlador;
  late TextEditingController _montoTotalControlador;
  late TextEditingController _montoPendienteControlador;
  late TextEditingController _notasControlador;

  @override
  void initState() {
    super.initState();
    _nombreControlador = TextEditingController(text: widget.deuda.tituloOEntidad);
    _montoTotalControlador = TextEditingController(text: widget.deuda.montoTotal.toStringAsFixed(2));
    _montoPendienteControlador = TextEditingController(text: widget.deuda.montoPendiente.toStringAsFixed(2));
    _notasControlador = TextEditingController(text: widget.deuda.notas ?? '');
  }

  @override
  void dispose() {
    _nombreControlador.dispose();
    _montoTotalControlador.dispose();
    _montoPendienteControlador.dispose();
    _notasControlador.dispose();
    super.dispose();
  }

  void _guardarEdicion() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double total = double.parse(_montoTotalControlador.text.replaceAll(',', ''));
      final double pendiente = double.parse(_montoPendienteControlador.text.replaceAll(',', ''));

      final deudaActualizada = DeudaModelo(
        id: widget.deuda.id,
        tituloOEntidad: _nombreControlador.text.trim(),
        tipoDeuda: widget.deuda.tipoDeuda,
        montoTotal: total,
        limiteAjustado: widget.deuda.limiteAjustado,
        montoPendiente: pendiente,
        fechaLimitePago: widget.deuda.fechaLimitePago,
        diaCorte: widget.deuda.diaCorte,
        colorTarjeta: widget.deuda.colorTarjeta,
        notas: _notasControlador.text.trim().isEmpty ? null : _notasControlador.text.trim(),
        historialPartidas: widget.deuda.historialPartidas,
      );

      widget.alGuardarCambios(deudaActualizada);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esMeDeben = widget.deuda.tipoDeuda == TipoDeuda.meDeben;
    final Color colorMarca = esMeDeben ? ColoresApp.ingresoVerde : ColoresApp.gastoRojo;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: ColoresApp.tarjeta(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formularioClave,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado con título y botón de cierre 'X'
                  Row(
                    children: [
                      Icon(
                        esMeDeben ? Icons.person_rounded : Icons.money_off_rounded,
                        color: colorMarca,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          esMeDeben ? 'Editar Deudor' : 'Editar Deuda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.texto(context),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar ventana',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

              // Nombre / Entidad
              TextFormField(
                controller: _nombreControlador,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: esMeDeben ? 'Nombre de la persona' : 'A quién le debes',
                  prefixIcon: Icon(Icons.person_rounded, color: colorMarca),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 14),

              // Monto Total Prestado
              TextFormField(
                controller: _montoTotalControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto Total Prestado / Deuda Inicial (\$)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '')) == null)
                    ? 'Monto inválido'
                    : null,
              ),
              const SizedBox(height: 14),

              // Saldo Pendiente Actual
              TextFormField(
                controller: _montoPendienteControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Saldo Pendiente Actual (\$)',
                  prefixIcon: const Icon(Icons.pending_actions_rounded),
                  helperText: 'Saldo que falta por pagar.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '')) == null)
                    ? 'Monto inválido'
                    : null,
              ),
              const SizedBox(height: 14),

              // Notas o detalles
              TextFormField(
                controller: _notasControlador,
                decoration: InputDecoration(
                  labelText: 'Notas o Motivo (Opcional)',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
