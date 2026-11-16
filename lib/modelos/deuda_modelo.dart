// ==========================================
// MODELO DE DATOS: DEUDAS / CUENTAS POR COBRAR
// ==========================================
class DeudaModelo {
  final String id;
  final String nombreDeudor;
  final double montoTotalPrestado;
  double montoPendiente;
  final DateTime fechaPrestamo;
  final String? notas;

  DeudaModelo({
    required this.id,
    required this.nombreDeudor,
    required this.montoTotalPrestado,
    required this.montoPendiente,
    required this.fechaPrestamo,
    this.notas,
  });

  // Getter para saber si la deuda ya fue pagada completamente
  bool get estaSaldada => montoPendiente <= 0;

  // Porcentaje recuperado de la deuda (0.0 a 1.0)
  double get porcentajeCobrado {
    if (montoTotalPrestado <= 0) return 1.0;
    final cobrado = montoTotalPrestado - montoPendiente;
    return (cobrado / montoTotalPrestado).clamp(0.0, 1.0);
  }
}
