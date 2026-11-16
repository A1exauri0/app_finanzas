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

  // Campos para vinculación con cobranza de deudas
  final String? idDeudaAsociada;
  final String? nombreDeudorAsociado;

  // Campos para gastos pagados con tarjeta de crédito
  final bool pagadoConTarjeta;
  final String? idTarjetaUtilizada;
  final String? nombreTarjetaUtilizada;

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
    this.pagadoConTarjeta = false,
    this.idTarjetaUtilizada,
    this.nombreTarjetaUtilizada,
  });

  // ==========================================
  // METODOS DE SERIALIZACION PARA SQLITE
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo.name,
      'iconoCodePoint': icono.codePoint,
      'categoria': categoria,
      'idDeudaAsociada': idDeudaAsociada,
      'nombreDeudorAsociado': nombreDeudorAsociado,
      'pagadoConTarjeta': pagadoConTarjeta ? 1 : 0,
      'idTarjetaUtilizada': idTarjetaUtilizada,
      'nombreTarjetaUtilizada': nombreTarjetaUtilizada,
    };
  }

  factory MovimientoModelo.fromMap(Map<String, dynamic> map) {
    return MovimientoModelo(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      tipo: (map['tipo'] as String) == 'ingreso'
          ? TipoMovimiento.ingreso
          : TipoMovimiento.gasto,
      icono: IconData(
        map['iconoCodePoint'] as int? ?? Icons.receipt_long_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      categoria: map['categoria'] as String,
      idDeudaAsociada: map['idDeudaAsociada'] as String?,
      nombreDeudorAsociado: map['nombreDeudorAsociado'] as String?,
      pagadoConTarjeta: (map['pagadoConTarjeta'] as int? ?? 0) == 1,
      idTarjetaUtilizada: map['idTarjetaUtilizada'] as String?,
      nombreTarjetaUtilizada: map['nombreTarjetaUtilizada'] as String?,
    );
  }
}
