// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// MODELO DE DATOS: GASTO FIJO O SUSCRIPCION RECURRENTE
// ==========================================
class GastoFijoModelo {
  final String id;
  String nombre;
  double monto;
  int diaPago; // Día del mes en que se efectúa el cargo (1 a 31)
  String categoria;
  IconData icono;
  Color color;
  bool pagarConTarjeta;
  String? idTarjeta;
  String? nombreTarjeta;
  String? ultimoMesPagado; // Formato 'YYYY-MM' para verificar pago del mes actual

  GastoFijoModelo({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.diaPago,
    this.categoria = 'Servicios',
    this.icono = Icons.receipt_long_rounded,
    this.color = const Color(0xFF1976D2),
    this.pagarConTarjeta = false,
    this.idTarjeta,
    this.nombreTarjeta,
    this.ultimoMesPagado,
  });

  // Clave del mes actual en formato 'YYYY-MM'
  static String get claveMesActual {
    final DateTime ahora = DateTime.now();
    return '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
  }

  // Verifica si el gasto fijo ya fue pagado en el mes corriente
  bool get estaPagadoEsteMes => ultimoMesPagado == claveMesActual;

  // Días que faltan para la fecha de pago en el mes actual
  int get diasParaPago {
    final DateTime ahora = DateTime.now();
    final int diaActual = ahora.day;
    if (diaActual <= diaPago) {
      return diaPago - diaActual;
    }
    // Si ya pasó el día en este mes, calcula respecto al próximo mes
    final DateTime siguienteMes = DateTime(ahora.year, ahora.month + 1, diaPago);
    return siguienteMes.difference(ahora).inDays;
  }

  // Marcar como pagado para el mes en curso
  void marcarPagadoMesActual() {
    ultimoMesPagado = claveMesActual;
  }

  // Desmarcar o revertir estado a pendiente
  void marcarComoPendiente() {
    ultimoMesPagado = null;
  }

  // ==========================================
  // SERIALIZACION Y DESERIALIZACION SQLITE
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'diaPago': diaPago,
      'categoria': categoria,
      'iconoCodePoint': icono.codePoint,
      'colorValue': color.toARGB32(),
      'pagarConTarjeta': pagarConTarjeta ? 1 : 0,
      'idTarjeta': idTarjeta,
      'nombreTarjeta': nombreTarjeta,
      'ultimoMesPagado': ultimoMesPagado,
    };
  }

  factory GastoFijoModelo.fromMap(Map<String, dynamic> map) {
    return GastoFijoModelo(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      monto: (map['monto'] as num).toDouble(),
      diaPago: map['diaPago'] as int? ?? 1,
      categoria: map['categoria'] as String? ?? 'Servicios',
      icono: IconData(
        map['iconoCodePoint'] as int? ?? Icons.receipt_long_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: map['colorValue'] != null
          ? Color(map['colorValue'] as int)
          : const Color(0xFF1976D2),
      pagarConTarjeta: (map['pagarConTarjeta'] as int? ?? 0) == 1,
      idTarjeta: map['idTarjeta'] as String?,
      nombreTarjeta: map['nombreTarjeta'] as String?,
      ultimoMesPagado: map['ultimoMesPagado'] as String?,
    );
  }
}
