// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// ENUMERADOR PARA TIPO DE MOVIMIENTO
// ==========================================
enum TipoMovimiento {
  ingreso,
  gasto,
}

// ==========================================
// MODELO DE DATOS DE UN MOVIMIENTO FINANCIERO
// ==========================================
class MovimientoModelo {
  final String id;
  final String titulo;
  final double monto;
  final DateTime fecha;
  final TipoMovimiento tipo;
  final IconData icono;
  final String categoria;
  final String? idDeudaAsociada;
  final String? nombreDeudorAsociado;

  MovimientoModelo({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.fecha,
    required this.tipo,
    required this.icono,
    required this.categoria,
    this.idDeudaAsociada,
    this.nombreDeudorAsociado,
  });
}
