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
// IMPORTACIONES DE COMPONENTES WIDGETS
// ==========================================
import '../componentes/cards/movimiento_item_tile.dart';
import '../componentes/modales/detalle_movimiento_modal.dart';
import '../componentes/modales/editar_movimiento_modal.dart';


// ==========================================
// ENUMERADOR PARA FILTROS RAPIDOS
// ==========================================
enum FiltroTipoMovimiento {
  todos,
  ingresos,
  gastos,
  tarjetas,
}

// ==========================================
// PANTALLA PRINCIPAL: MODULO DE MOVIMIENTOS
// ==========================================
class MovimientosScreen extends StatefulWidget {
  final List<MovimientoModelo> listaMovimientos;
  final List<DeudaModelo> listaDeudas;
  final Function(String idMovimiento) alEliminarMovimiento;
  final Function(MovimientoModelo movimientoActualizado) alActualizarMovimiento;
  final VoidCallback? alPulsarNuevoMovimiento;

  const MovimientosScreen({
    super.key,
    required this.listaMovimientos,
    this.listaDeudas = const [],
    required this.alEliminarMovimiento,
    required this.alActualizarMovimiento,
    this.alPulsarNuevoMovimiento,
  });

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  // Controlador del campo de búsqueda
  final TextEditingController _busquedaControlador = TextEditingController();

  // Filtro activo
  FiltroTipoMovimiento _filtroSeleccionado = FiltroTipoMovimiento.todos;

  // Texto de búsqueda activo
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _busquedaControlador.addListener(() {
      setState(() {
        _terminoBusqueda = _busquedaControlador.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _busquedaControlador.dispose();
    super.dispose();
  }

  // Filtrado de la lista reactivamente
  List<MovimientoModelo> get _movimientosFiltrados {
    return widget.listaMovimientos.where((mov) {
      // 1. Filtro por tipo o tarjeta
      if (_filtroSeleccionado == FiltroTipoMovimiento.ingresos &&
          mov.tipo != TipoMovimiento.ingreso) {
        return false;
      }
      if (_filtroSeleccionado == FiltroTipoMovimiento.gastos &&
          mov.tipo != TipoMovimiento.gasto) {
        return false;
      }
      if (_filtroSeleccionado == FiltroTipoMovimiento.tarjetas && !mov.pagadoConTarjeta) {
        return false;
      }

      // 2. Filtro de búsqueda por concepto, categoría o tarjeta
      if (_terminoBusqueda.isNotEmpty) {
        final conceptoCoincide = mov.titulo.toLowerCase().contains(_terminoBusqueda);
        final categoriaCoincide = mov.categoria.toLowerCase().contains(_terminoBusqueda);
        final tarjetaCoincide = mov.nombreTarjetaUtilizada?.toLowerCase().contains(_terminoBusqueda) ?? false;
        final deudorCoincide = mov.nombreDeudorAsociado?.toLowerCase().contains(_terminoBusqueda) ?? false;

        return conceptoCoincide || categoriaCoincide || tarjetaCoincide || deudorCoincide;
      }

      return true;
    }).toList();
  }

  // Cálculos de totales del filtro actual
  double get _totalIngresosFiltrados => _movimientosFiltrados
      .where((m) => m.tipo == TipoMovimiento.ingreso)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _totalGastosFiltrados => _movimientosFiltrados
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (acum, m) => acum + m.monto);

  double get _balanceNetoFiltrado => _totalIngresosFiltrados - _totalGastosFiltrados;

  // Formato legible para grupos de fecha
  String _obtenerEtiquetaFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final ayerSinHora = hoySinHora.subtract(const Duration(days: 1));

    if (fechaSinHora == hoySinHora) {
      return 'Hoy';
    } else if (fechaSinHora == ayerSinHora) {
      return 'Ayer';
    } else {
      const List<String> meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
    }
  }

  // Agrupación de movimientos por día
  Map<String, List<MovimientoModelo>> _agruparMovimientosPorFecha(
      List<MovimientoModelo> movimientos) {
    final Map<String, List<MovimientoModelo>> agrupados = {};

    // Ordenar de más reciente a más antiguo
    final listaOrdenada = List<MovimientoModelo>.from(movimientos)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    for (final mov in listaOrdenada) {
      final claveFecha = _obtenerEtiquetaFecha(mov.fecha);
      if (!agrupados.containsKey(claveFecha)) {
        agrupados[claveFecha] = [];
      }
      agrupados[claveFecha]!.add(mov);
    }

    return agrupados;
  }

  // Abrir modal de detalles y acciones
  void _mostrarDetallesMovimiento(MovimientoModelo movimiento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetalleMovimientoModal(
        movimiento: movimiento,
        alPulsarEditar: () {
          Navigator.pop(ctx);
          _mostrarModalEdicion(movimiento);
        },
        alPulsarEliminar: () {
          Navigator.pop(ctx);
          _confirmarEliminacion(movimiento);
        },
      ),
    );
  }

  // Modal para editar el movimiento
  void _mostrarModalEdicion(MovimientoModelo movimiento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.tarjeta(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => EditarMovimientoModal(
        movimientoOriginal: movimiento,
        alGuardarCambios: widget.alActualizarMovimiento,
      ),
    );
  }

  // Diálogo para confirmar eliminación
  void _confirmarEliminacion(MovimientoModelo movimiento) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar movimiento?'),
        content: Text(
          'Se eliminará "${movimiento.titulo}" por \$${movimiento.monto.toStringAsFixed(2)}.\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.gastoRojo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.alEliminarMovimiento(movimiento.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movimientos = _movimientosFiltrados;
    final movimientosAgrupados = _agruparMovimientosPorFecha(movimientos);

    return Scaffold(
      backgroundColor: ColoresApp.fondo(context),
      appBar: AppBar(
        title: Text(
          'Historial de Movimientos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: ColoresApp.texto(context),
          ),
        ),
        backgroundColor: ColoresApp.fondo(context),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _busquedaControlador,
              style: TextStyle(color: ColoresApp.texto(context)),
              decoration: InputDecoration(
                hintText: 'Buscar por concepto, categoría o tarjeta...',
                hintStyle: TextStyle(color: ColoresApp.subtexto(context)),
                prefixIcon: Icon(Icons.search_rounded, color: ColoresApp.subtexto(context)),
                suffixIcon: _terminoBusqueda.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: ColoresApp.subtexto(context)),
                        onPressed: () => _busquedaControlador.clear(),
                      )
                    : null,
                filled: true,
                fillColor: ColoresApp.tarjeta(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: ColoresApp.borde(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: ColoresApp.borde(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ColoresApp.primarioVerde, width: 1.5),
                ),
              ),
            ),
          ),

          // Filtros rápidos segmentados
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _ChipFiltro(
                  etiqueta: 'Todos (${widget.listaMovimientos.length})',
                  icono: Icons.all_inclusive_rounded,
                  estaSeleccionado: _filtroSeleccionado == FiltroTipoMovimiento.todos,
                  alSeleccionar: () => setState(() => _filtroSeleccionado = FiltroTipoMovimiento.todos),
                ),
                const SizedBox(width: 8),
                _ChipFiltro(
                  etiqueta: 'Ingresos',
                  icono: Icons.arrow_downward_rounded,
                  colorActivo: ColoresApp.ingresoVerde,
                  estaSeleccionado: _filtroSeleccionado == FiltroTipoMovimiento.ingresos,
                  alSeleccionar: () => setState(() => _filtroSeleccionado = FiltroTipoMovimiento.ingresos),
                ),
                const SizedBox(width: 8),
                _ChipFiltro(
                  etiqueta: 'Gastos',
                  icono: Icons.arrow_upward_rounded,
                  colorActivo: ColoresApp.gastoRojo,
                  estaSeleccionado: _filtroSeleccionado == FiltroTipoMovimiento.gastos,
                  alSeleccionar: () => setState(() => _filtroSeleccionado = FiltroTipoMovimiento.gastos),
                ),
                const SizedBox(width: 8),
                _ChipFiltro(
                  etiqueta: 'Con Tarjeta',
                  icono: Icons.credit_card_rounded,
                  colorActivo: Colors.purple.shade700,
                  estaSeleccionado: _filtroSeleccionado == FiltroTipoMovimiento.tarjetas,
                  alSeleccionar: () => setState(() => _filtroSeleccionado = FiltroTipoMovimiento.tarjetas),
                ),
              ],
            ),
          ),

          // Tarjeta de Resumen Financiero del Filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColoresApp.tarjeta(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: ColoresApp.esOscuro(context) ? 0.2 : 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ingresos del filtro
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 14, color: ColoresApp.ingresoVerde),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Ingresos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '+\$${_totalIngresosFiltrados.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.ingresoVerde,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(width: 1, height: 35, color: ColoresApp.borde(context)),

                  // Gastos del filtro
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 14, color: ColoresApp.gastoRojo),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Gastos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '-\$${_totalGastosFiltrados.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.gastoRojo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(width: 1, height: 35, color: ColoresApp.borde(context)),

                  // Balance neto
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance Neto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: ColoresApp.subtexto(context)),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_balanceNetoFiltrado >= 0 ? '+' : ''}\$${_balanceNetoFiltrado.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _balanceNetoFiltrado >= 0
                                    ? ColoresApp.ingresoVerde
                                    : ColoresApp.gastoRojo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Listado de Movimientos
          Expanded(
            child: movimientos.isEmpty
                ? _EstadoVacioMovimientos(
                    terminoBusqueda: _terminoBusqueda,
                    alLimpiarFiltros: () {
                      setState(() {
                        _busquedaControlador.clear();
                        _filtroSeleccionado = FiltroTipoMovimiento.todos;
                      });
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: movimientosAgrupados.length,
                    itemBuilder: (context, index) {
                      final claveFecha = movimientosAgrupados.keys.elementAt(index);
                      final listaPorFecha = movimientosAgrupados[claveFecha]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado de Fecha
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              claveFecha,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.textoSecundario,
                              ),
                            ),
                          ),

                          // Elementos de este día
                          ...listaPorFecha.map((mov) {
                            return MovimientoItemTile(
                              movimiento: mov,
                              alPulsar: () => _mostrarDetallesMovimiento(mov),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: CHIP DE FILTRO RAPIDO
// ==========================================
class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool estaSeleccionado;
  final VoidCallback alSeleccionar;
  final Color? colorActivo;

  const _ChipFiltro({
    required this.etiqueta,
    required this.icono,
    required this.estaSeleccionado,
    required this.alSeleccionar,
    this.colorActivo,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = colorActivo ?? ColoresApp.primarioVerde;

    return FilterChip(
      selected: estaSeleccionado,
      showCheckmark: false,
      avatar: Icon(
        icono,
        size: 16,
        color: estaSeleccionado ? Colors.white : ColoresApp.subtexto(context),
      ),
      label: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 13,
          fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
          color: estaSeleccionado ? Colors.white : ColoresApp.texto(context),
        ),
      ),
      backgroundColor: ColoresApp.tarjeta(context),
      selectedColor: colorPrincipal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estaSeleccionado ? colorPrincipal : ColoresApp.borde(context),
        ),
      ),
      onSelected: (_) => alSeleccionar(),
    );
  }
}

// ==========================================
// SUBCOMPONENTE PRIVADO: ESTADO VACIO
// ==========================================
class _EstadoVacioMovimientos extends StatelessWidget {
  final String terminoBusqueda;
  final VoidCallback alLimpiarFiltros;

  const _EstadoVacioMovimientos({
    required this.terminoBusqueda,
    required this.alLimpiarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresApp.tarjetaElevada(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                terminoBusqueda.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_outlined,
                size: 54,
                color: ColoresApp.subtexto(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              terminoBusqueda.isNotEmpty
                  ? 'Sin coincidencias para "$terminoBusqueda"'
                  : 'No hay movimientos en esta vista',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColoresApp.texto(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              terminoBusqueda.isNotEmpty
                  ? 'Prueba con otro término de búsqueda o restablece los filtros.'
                  : 'Registra un ingreso o gasto usando el botón (+) central.',
              style: TextStyle(fontSize: 13, color: ColoresApp.subtexto(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: alLimpiarFiltros,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Restablecer filtros'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
