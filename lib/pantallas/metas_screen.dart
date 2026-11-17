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
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/cards/meta_progreso_card.dart';
import '../componentes/modales/nueva_meta_modal.dart';


// ==========================================
// PANTALLA: GESTION DE METAS Y OBJETIVOS DE COMPRA
// ==========================================
class MetasScreen extends StatefulWidget {
  final List<MetaModelo> listaMetas;
  final Function(MetaModelo) alCrearMeta;
  final Function(MetaModelo) alActualizarMeta;
  final Function(String idMeta) alEliminarMeta;
  final Function(String idMeta, double montoAbono) alAbonarMeta;
  final Function(String idMeta, double montoRetiro) alRetirarMeta;

  const MetasScreen({
    super.key,
    required this.listaMetas,
    required this.alCrearMeta,
    required this.alActualizarMeta,
    required this.alEliminarMeta,
    required this.alAbonarMeta,
    required this.alRetirarMeta,
  });

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  // Filtro seleccionado (0: Todas, 1: En Progreso, 2: Cumplidas)
  int _filtroSeleccionado = 0;

  // Abrir modal de nueva meta
  void _mostrarModalNuevaMeta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.tarjeta(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevaMetaModal(
        alGuardarMeta: widget.alCrearMeta,
      ),
    );
  }

  // Abrir modal de edición para una meta existente
  void _mostrarModalEditarMeta(MetaModelo meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.tarjeta(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => NuevaMetaModal(
        metaParaEditar: meta,
        alGuardarMeta: (metaActualizada) {
          widget.alActualizarMeta(metaActualizada);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meta "${metaActualizada.titulo}" actualizada'),
              backgroundColor: ColoresApp.primarioVerde,
            ),
          );
        },
      ),
    );
  }

  // Diálogo de confirmación para eliminar una meta
  void _confirmarEliminarMeta(MetaModelo meta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta meta?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la meta "${meta.titulo}"?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColoresApp.gastoRojo),
            onPressed: () {
              widget.alEliminarMeta(meta.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Meta "${meta.titulo}" eliminada'),
                  backgroundColor: ColoresApp.gastoRojo,
                ),
              );
            },
            child: const Text('Eliminar Meta'),
          ),
        ],
      ),
    );
  }

  // Diálogo para abonar ahorro a una meta
  void _mostrarDialogoAbonar(MetaModelo meta) {
    final TextEditingController abonoControlador = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: meta.color.withValues(alpha: 0.15),
              child: Icon(meta.icono, size: 16, color: meta.color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Abonar a "${meta.titulo}"')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ahorrado actualmente: \$${meta.montoAhorrado.toStringAsFixed(2)}'),
            Text('Monto objetivo: \$${meta.montoObjetivo.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: abonoControlador,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto a abonar (\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: meta.color),
            onPressed: () {
              final double? monto = double.tryParse(abonoControlador.text.replaceAll(',', ''));
              if (monto != null && monto > 0) {
                widget.alAbonarMeta(meta.id, monto);
                Navigator.of(ctx).pop();

                final bool seCompleto = (meta.montoAhorrado + monto) >= meta.montoObjetivo;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      seCompleto
                          ? '🎉 ¡Felicidades! Has cumplido tu meta "${meta.titulo}"'
                          : 'Se abonaron \$${monto.toStringAsFixed(2)} a "${meta.titulo}"',
                    ),
                    backgroundColor: seCompleto ? Colors.green.shade700 : meta.color,
                  ),
                );
              }
            },
            child: const Text('Confirmar Abono'),
          ),
        ],
      ),
    );
  }

  // Diálogo para retirar ahorro de una meta y devolverlo al disponible
  void _mostrarDialogoRetirar(MetaModelo meta) {
    final TextEditingController retiroControlador = TextEditingController();
    String? errorTexto;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: meta.color.withValues(alpha: 0.15),
                  child: Icon(meta.icono, size: 16, color: meta.color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Retirar de "${meta.titulo}"')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ahorrado actualmente: \$${meta.montoAhorrado.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                TextField(
                  controller: retiroControlador,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Monto a retirar (\$)',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: const OutlineInputBorder(),
                    errorText: errorTexto,
                  ),
                  onChanged: (val) {
                    final double? monto = double.tryParse(val.replaceAll(',', ''));
                    if (monto != null && monto > meta.montoAhorrado) {
                      setStateModal(() {
                        errorTexto = 'No puedes retirar más de \$${meta.montoAhorrado.toStringAsFixed(2)}';
                      });
                    } else if (errorTexto != null) {
                      setStateModal(() {
                        errorTexto = null;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ColoresApp.gastoRojo),
                onPressed: () {
                  final double? monto = double.tryParse(retiroControlador.text.replaceAll(',', ''));
                  if (monto == null || monto <= 0) {
                    setStateModal(() {
                      errorTexto = 'Ingresa un monto válido';
                    });
                    return;
                  }
                  if (monto > meta.montoAhorrado) {
                    setStateModal(() {
                      errorTexto = 'No puedes retirar más de lo ahorrado';
                    });
                    return;
                  }
                  widget.alRetirarMeta(meta.id, monto);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Se retiraron \$${monto.toStringAsFixed(2)} de "${meta.titulo}" y volvieron a tu dinero disponible',
                      ),
                      backgroundColor: ColoresApp.primarioVerde,
                    ),
                  );
                },
                child: const Text('Confirmar Retiro'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int metasCumplidas = widget.listaMetas.where((m) => m.estaCumplida).length;

    // Metas filtradas
    final List<MetaModelo> metasFiltradas = widget.listaMetas.where((m) {
      if (_filtroSeleccionado == 1) return !m.estaCumplida;
      if (_filtroSeleccionado == 2) return m.estaCumplida;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      appBar: AppBar(
        title: Text(
          'Objetivos de Compra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ColoresApp.texto(context),
          ),
        ),
        backgroundColor: ColoresApp.fondo(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Filtros (SegmentedButton)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text('Todas (${widget.listaMetas.length})'),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('En Progreso (${widget.listaMetas.length - metasCumplidas})'),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Logradas ($metasCumplidas)'),
                  ),
                ],
                selected: {_filtroSeleccionado},
                onSelectionChanged: (nuevaSeleccion) {
                  setState(() {
                    _filtroSeleccionado = nuevaSeleccion.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Listado de Metas o Estado Vacío
            if (metasFiltradas.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      _filtroSeleccionado == 2
                          ? Icons.military_tech_outlined
                          : Icons.flag_outlined,
                      size: 54,
                      color: ColoresApp.subtexto(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _filtroSeleccionado == 2
                          ? 'Aún no has completado ninguna meta. ¡Sigue ahorrando!'
                          : 'No hay metas en esta categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColoresApp.subtexto(context)),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metasFiltradas.length,
                itemBuilder: (context, index) {
                  final meta = metasFiltradas[index];
                  return MetaProgresoCard(
                    meta: meta,
                    alPulsarAbonar: _mostrarDialogoAbonar,
                    alPulsarRetirar: _mostrarDialogoRetirar,
                    alPulsarEditar: _mostrarModalEditarMeta,
                    alPulsarEliminar: _confirmarEliminarMeta,
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton.extended(
          onPressed: _mostrarModalNuevaMeta,
          backgroundColor: const Color(0xFFE65100),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Nueva Meta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
