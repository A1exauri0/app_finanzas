// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// MODELO DE DATOS: OBJETIVO DE COMPRA / META DE AHORRO
// ==========================================
class MetaModelo {
  final String id;
  String titulo;
  double montoObjetivo;
  double montoAhorrado;
  DateTime? fechaObjetivo;
  IconData icono;
  Color color;
  String categoria;
  String? notas;

  MetaModelo({
    required this.id,
    required this.titulo,
    required this.montoObjetivo,
    required this.montoAhorrado,
    this.fechaObjetivo,
    this.icono = Icons.flag_rounded,
    this.color = const Color(0xFFEF6C00), // Naranja por defecto
    this.categoria = 'General',
    this.notas,
  });

  // Getter de porcentaje completado (0.0 a 1.0)
  double get porcentajeProgreso {
    if (montoObjetivo <= 0) return 1.0;
    return (montoAhorrado / montoObjetivo).clamp(0.0, 1.0);
  }

  // Monto faltante para cumplir la meta
  double get montoFaltante {
    final faltante = montoObjetivo - montoAhorrado;
    return faltante < 0 ? 0.0 : faltante;
  }

  // Indica si ya se alcanzó la meta
  bool get estaCumplida => montoAhorrado >= montoObjetivo;

  // Días restantes para alcanzar la meta (si tiene fecha)
  int? get diasRestantes {
    if (fechaObjetivo == null) return null;
    final diferencia = fechaObjetivo!.difference(DateTime.now()).inDays;
    return diferencia < 0 ? 0 : diferencia;
  }

  // Ahorro mensual sugerido para llegar a la fecha límite
  double? get ahorroMensualSugerido {
    final dias = diasRestantes;
    if (dias == null || dias <= 0 || estaCumplida) return null;
    final meses = dias / 30.0;
    if (meses <= 0) return montoFaltante;
    return montoFaltante / meses;
  }

  // Método para abonar dinero a la meta
  void abonar(double monto) {
    montoAhorrado += monto;
  }

  // Método para retirar dinero de la meta si es necesario
  void retirar(double monto) {
    montoAhorrado -= monto;
    if (montoAhorrado < 0) montoAhorrado = 0.0;
  }
}
