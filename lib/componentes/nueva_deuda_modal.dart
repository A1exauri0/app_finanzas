// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';
import '../constantes/catalogo_bancos.dart';

// ==========================================
// IMPORTACIONES DE MODELOS
// ==========================================
import '../modelos/deuda_modelo.dart';

// ==========================================
// COMPONENTE VISUAL: MODAL PARA CREAR DEUDA O TARJETA
// ==========================================
class NuevaDeudaModal extends StatefulWidget {
  final TipoDeuda tipoInicial;
  final List<DeudaModelo> listaDeudasExistentes;
  final Function(DeudaModelo) alGuardarDeuda;
  final Function(String idDeuda, String concepto, double monto, DateTime fecha)? alAcumularDeuda;

  const NuevaDeudaModal({
    super.key,
    this.tipoInicial = TipoDeuda.tarjetaCredito,
    this.listaDeudasExistentes = const [],
    required this.alGuardarDeuda,
    this.alAcumularDeuda,
  });

  @override
  State<NuevaDeudaModal> createState() => _NuevaDeudaModalState();
}

class _NuevaDeudaModalState extends State<NuevaDeudaModal> {
  static const String _idNuevaPersona = '__NUEVA_PERSONA__';

  // Clave del formulario
  final _formularioClave = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _tituloControlador = TextEditingController();
  final TextEditingController _montoTotalControlador = TextEditingController();
  final TextEditingController _limiteAjustadoControlador = TextEditingController();
  final TextEditingController _montoPendienteControlador = TextEditingController();
  final TextEditingController _notasControlador = TextEditingController();

  // Estados locales
  late TipoDeuda _tipoDeudaSeleccionada;
  DateTime? _fechaLimiteSeleccionada;
  int? _diaCorteSeleccionado = 15;
  Color _colorTarjetaSeleccionada = CatalogoBancos.listaBancos.first.color;
  BancoItem? _bancoItemSeleccionado;

  // Estado del dropdown de selección de persona existente o nueva
  String _personaSeleccionadaId = _idNuevaPersona;

  @override
  void initState() {
    super.initState();
    _tipoDeudaSeleccionada = widget.tipoInicial;

    final bancosDisponibles = _obtenerBancosDisponibles();
    if (bancosDisponibles.isNotEmpty) {
      _bancoItemSeleccionado = bancosDisponibles.first;
      _colorTarjetaSeleccionada = bancosDisponibles.first.color;
      if (_tipoDeudaSeleccionada == TipoDeuda.tarjetaCredito) {
        _tituloControlador.text = bancosDisponibles.first.nombre;
      }
    } else {
      _bancoItemSeleccionado = CatalogoBancos.otroBanco;
      _colorTarjetaSeleccionada = CatalogoBancos.otroBanco.color;
    }
  }

  @override
  void dispose() {
    _tituloControlador.dispose();
    _montoTotalControlador.dispose();
    _limiteAjustadoControlador.dispose();
    _montoPendienteControlador.dispose();
    _notasControlador.dispose();
    super.dispose();
  }

  // Filtra los bancos que aún no están registrados como tarjeta
  List<BancoItem> _obtenerBancosDisponibles() {
    final nombresTarjetasRegistradas = widget.listaDeudasExistentes
        .where((d) => d.tipoDeuda == TipoDeuda.tarjetaCredito)
        .map((d) => d.tituloOEntidad.toLowerCase().trim())
        .toSet();

    final filtrados = CatalogoBancos.listaBancos
        .where((banco) => !nombresTarjetasRegistradas.contains(banco.nombre.toLowerCase().trim()))
        .toList();

    return [...filtrados, CatalogoBancos.otroBanco];
  }

  // Personas existentes según el tipo actual (Me Deben / Debo)
  List<DeudaModelo> _obtenerPersonasExistentes() {
    return widget.listaDeudasExistentes
        .where((d) => d.tipoDeuda == _tipoDeudaSeleccionada)
        .toList();
  }

  // Guardar la deuda o acumular a persona existente
  void _guardarDeuda() {
    if (_formularioClave.currentState?.validate() ?? false) {
      final double monto = double.parse(_montoTotalControlador.text.replaceAll(',', ''));
      final bool esAcumularExistente = _personaSeleccionadaId != _idNuevaPersona;

      // Si se seleccionó una persona existente en el dropdown
      if (esAcumularExistente && widget.alAcumularDeuda != null) {
        final concepto = _notasControlador.text.trim().isNotEmpty
            ? _notasControlador.text.trim()
            : 'Préstamo adicional';

        widget.alAcumularDeuda!(
          _personaSeleccionadaId,
          concepto,
          monto,
          DateTime.now(),
        );
        Navigator.of(context).pop();
        return;
      }

      // Si es una nueva persona o una tarjeta
      final double pendiente = _montoPendienteControlador.text.isEmpty
          ? monto
          : double.parse(_montoPendienteControlador.text.replaceAll(',', ''));

      final double? limiteAjustado = _limiteAjustadoControlador.text.trim().isNotEmpty
          ? double.tryParse(_limiteAjustadoControlador.text.replaceAll(',', ''))
          : null;

      final nuevaDeuda = DeudaModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tituloOEntidad: _tituloControlador.text.trim(),
        tipoDeuda: _tipoDeudaSeleccionada,
        montoTotal: monto,
        limiteAjustado: limiteAjustado,
        montoPendiente: pendiente,
        fechaLimitePago: _fechaLimiteSeleccionada,
        diaCorte: _tipoDeudaSeleccionada == TipoDeuda.tarjetaCredito ? _diaCorteSeleccionado : null,
        colorTarjeta: _tipoDeudaSeleccionada == TipoDeuda.tarjetaCredito
            ? _colorTarjetaSeleccionada
            : null,
        notas: _notasControlador.text.trim().isEmpty ? null : _notasControlador.text.trim(),
      );

      // Si no es tarjeta, inicializamos la primera partida en el historial
      if (_tipoDeudaSeleccionada != TipoDeuda.tarjetaCredito) {
        nuevaDeuda.historialPartidas.add(
          PartidaDeudaModelo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            concepto: _notasControlador.text.trim().isNotEmpty
                ? _notasControlador.text.trim()
                : 'Préstamo inicial',
            monto: monto,
            fecha: DateTime.now(),
          ),
        );
      }

      widget.alGuardarDeuda(nuevaDeuda);
      Navigator.of(context).pop();
    }
  }

  // Selector de fecha para día de corte
  Future<void> _abrirSelectorFechaCorte() async {
    final DateTime ahora = DateTime.now();
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      helpText: 'SELECCIONA EL DÍA DE CORTE DE TU TARJETA',
      initialDate: DateTime(ahora.year, ahora.month, _diaCorteSeleccionado ?? 15),
      firstDate: DateTime(ahora.year, ahora.month, 1),
      lastDate: DateTime(ahora.year, ahora.month, 31),
    );

    if (fechaElegida != null) {
      setState(() {
        _diaCorteSeleccionado = fechaElegida.day;
      });
    }
  }

  // Selector de fecha límite de pago
  Future<void> _abrirSelectorFechaLimite() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimiteSeleccionada ?? DateTime.now().add(const Duration(days: 20)),
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
    final bool esNuevaPersona = _personaSeleccionadaId == _idNuevaPersona;
    final bancosDisponibles = _obtenerBancosDisponibles();
    final personasExistentes = _obtenerPersonasExistentes();

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
              Text(
                esTarjeta
                    ? 'Registrar Tarjeta de Crédito'
                    : (esMeDeben ? 'Registrar Préstamo (Me Deben)' : 'Registrar Deuda Mía (Debo)'),
                style: const TextStyle(
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
                    value: TipoDeuda.tarjetaCredito,
                    label: Text('Tarjeta'),
                    icon: Icon(Icons.credit_card_rounded),
                  ),
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
                ],
                selected: {_tipoDeudaSeleccionada},
                onSelectionChanged: (nuevaSeleccion) {
                  setState(() {
                    _tipoDeudaSeleccionada = nuevaSeleccion.first;
                    _personaSeleccionadaId = _idNuevaPersona;
                    if (_tipoDeudaSeleccionada != TipoDeuda.tarjetaCredito) {
                      _tituloControlador.clear();
                    } else if (_bancoItemSeleccionado != null) {
                      _tituloControlador.text = _bancoItemSeleccionado!.nombre;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Dropdown para seleccionar Banco si es Tarjeta
              if (esTarjeta) ...[
                DropdownButtonFormField<BancoItem>(
                  initialValue: _bancoItemSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Banco o Entidad Financiera',
                    prefixIcon: Icon(Icons.account_balance_rounded, color: _colorTarjetaSeleccionada),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: bancosDisponibles.map((banco) {
                    return DropdownMenuItem<BancoItem>(
                      value: banco,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 8, backgroundColor: banco.color),
                          const SizedBox(width: 12),
                          Text(banco.nombre),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (BancoItem? nuevoBanco) {
                    if (nuevoBanco != null) {
                      setState(() {
                        _bancoItemSeleccionado = nuevoBanco;
                        _colorTarjetaSeleccionada = nuevoBanco.color;
                        if (nuevoBanco.nombre != CatalogoBancos.otroBanco.nombre) {
                          _tituloControlador.text = nuevoBanco.nombre;
                        } else {
                          _tituloControlador.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Dropdown unificado para Personas (con opción de Nueva Persona)
              if (!esTarjeta) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('persona_dropdown_$_tipoDeudaSeleccionada'),
                  initialValue: _personaSeleccionadaId,
                  decoration: InputDecoration(
                    labelText: esMeDeben ? 'Deudor (Persona)' : 'Acreedor',
                    prefixIcon: Icon(
                      esNuevaPersona ? Icons.person_add_rounded : Icons.person_rounded,
                      color: ColoresApp.primarioVerde,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: _idNuevaPersona,
                      child: Row(
                        children: const [
                          Icon(Icons.add_circle_outline_rounded, size: 20, color: ColoresApp.primarioVerde),
                          SizedBox(width: 10),
                          Text(
                            '+ Registrar nueva persona',
                            style: TextStyle(fontWeight: FontWeight.bold, color: ColoresApp.primarioVerde),
                          ),
                        ],
                      ),
                    ),
                    ...personasExistentes.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text('${p.tituloOEntidad} (Saldo: \$${p.montoPendiente.toStringAsFixed(2)})'),
                      );
                    }),
                  ],
                  onChanged: (String? nuevoValor) {
                    if (nuevoValor != null) {
                      setState(() {
                        _personaSeleccionadaId = nuevoValor;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Nombre / Entidad (solo si es tarjeta o es una nueva persona)
              if (esTarjeta || esNuevaPersona) ...[
                TextFormField(
                  controller: _tituloControlador,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: esTarjeta
                        ? 'Nombre o alias de la tarjeta'
                        : (esMeDeben ? 'Nombre de la nueva persona (ej. Juan Pérez)' : 'A quién le debes (ej. Préstamo Amigo)'),
                    prefixIcon: Icon(esTarjeta ? Icons.credit_card_rounded : Icons.person_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa un nombre o entidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Monto a prestar o Límite de tarjeta
              TextFormField(
                controller: _montoTotalControlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: !esNuevaPersona
                      ? 'Monto del nuevo préstamo a acumular (\$)'
                      : (esTarjeta ? 'Límite de Crédito Total (\$)' : 'Monto Prestado / Deuda (\$)'),
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

              // Si es tarjeta: Límite de control propio
              if (esTarjeta) ...[
                TextFormField(
                  controller: _limiteAjustadoControlador,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Límite Ajustado de Control Propio (Opcional) (\$)',
                    prefixIcon: const Icon(Icons.tune_rounded),
                    helperText: 'Tope máximo mensual que tú decides gastar (ej. \$2000).',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Saldo pendiente inicial (solo para nueva persona o tarjeta)
              if (esNuevaPersona || esTarjeta) ...[
                TextFormField(
                  controller: _montoPendienteControlador,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: esTarjeta ? 'Saldo Usado a Pagar Inicial (\$)' : 'Saldo Pendiente Inicial (\$)',
                    helperText: esTarjeta
                        ? 'Si la tarjeta está en cero, pon 0 o déjalo vacío.'
                        : 'Si es la deuda completa, déjalo vacío.',
                    prefixIcon: const Icon(Icons.pending_actions_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Concepto o Notas del préstamo
              TextFormField(
                controller: _notasControlador,
                decoration: InputDecoration(
                  labelText: !esNuevaPersona
                      ? 'Motivo del nuevo préstamo (ej. Gasolina, Comida)'
                      : 'Notas o Motivo (Opcional)',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Fecha de Corte para tarjetas
              if (esTarjeta) ...[
                OutlinedButton.icon(
                  onPressed: _abrirSelectorFechaCorte,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    _diaCorteSeleccionado != null
                        ? 'Día de corte mensual: Día $_diaCorteSeleccionado de cada mes'
                        : 'Seleccionar día de corte de la tarjeta',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      ? 'Fecha Límite de Pago Próxima (Opcional)'
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
                  backgroundColor: esTarjeta ? _colorTarjetaSeleccionada : ColoresApp.primarioVerde,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  !esNuevaPersona
                      ? 'Acumular Préstamo a la Persona'
                      : (esTarjeta ? 'Guardar Tarjeta' : 'Guardar Deuda'),
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
