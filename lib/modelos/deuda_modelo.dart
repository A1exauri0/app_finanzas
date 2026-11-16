// ==========================================
// ENUMERADOR PARA CLASIFICACION DE DEUDAS
// ==========================================
enum TipoDeuda {
  meDeben,         // Cuentas por cobrar (dinero prestado a terceros)
  debo,            // Deudas propias por pagar (préstamos personales, etc.)
  tarjetaCredito,  // Tarjetas de crédito revolventes
}

// ==========================================
// MODELO DE DATOS: GESTION DE DEUDAS Y TARJETAS
// ==========================================
class DeudaModelo {
  final String id;
  final String tituloOEntidad;     // Ej. "Juan Pérez", "Tarjeta Visa BBVA"
  final TipoDeuda tipoDeuda;
  final double montoTotal;         // Monto prestado / Límite de crédito
  double montoPendiente;           // Lo que falta pagar o saldo usado
  final DateTime? fechaLimitePago;  // Fecha límite para liquidar
  final int? diaCorte;             // Día del mes en que corta la tarjeta (1-31)
  final String? notas;

  DeudaModelo({
    required this.id,
    required this.tituloOEntidad,
    required this.tipoDeuda,
    required this.montoTotal,
    required this.montoPendiente,
    this.fechaLimitePago,
    this.diaCorte,
    this.notas,
  });

  // Getter para verificar si está totalmente saldada
  bool get estaSaldada => montoPendiente <= 0;

  // Porcentaje liquidado o pagado (0.0 a 1.0)
  double get porcentajePagado {
    if (montoTotal <= 0) return 1.0;
    final pagado = montoTotal - montoPendiente;
    return (pagado / montoTotal).clamp(0.0, 1.0);
  }

  // Getter de conveniencia para compatibilidad
  String get nombreDeudor => tituloOEntidad;
}
