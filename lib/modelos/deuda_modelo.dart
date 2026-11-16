// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// ENUMERADOR PARA CLASIFICACION DE DEUDAS
// ==========================================
enum TipoDeuda {
  tarjetaCredito,  // Tarjetas de crédito revolventes
  meDeben,         // Cuentas por cobrar (dinero prestado a terceros)
  debo,            // Deudas propias por pagar (préstamos personales, etc.)
}

// ==========================================
// MODELO AUXILIAR: PARTIDA O REGISTRO DE HISTORIAL
// ==========================================
class PartidaDeudaModelo {
  final String id;
  final String concepto;
  final double monto;
  final DateTime fecha;
  final bool esAbono; // true: pago/abono que reduce saldo; false: cargo o nuevo préstamo

  PartidaDeudaModelo({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.fecha,
    this.esAbono = false,
  });
}

// ==========================================
// MODELO DE DATOS: GESTION DE DEUDAS Y TARJETAS
// ==========================================
class DeudaModelo {
  final String id;
  String tituloOEntidad;           // Ej. "Nu México", "Juan Pérez"
  final TipoDeuda tipoDeuda;
  double montoTotal;               // Límite de crédito otorgado o total acumulado prestado
  double? limiteAjustado;          // Límite personalizado de control (ej. tope de \$2000 teniendo \$4000)
  double montoPendiente;           // Saldo usado o deuda pendiente actual
  DateTime? fechaLimitePago;       // Fecha límite para liquidar sin intereses
  int? diaCorte;                   // Día del mes de corte (1-31)
  final Color? colorTarjeta;       // Color característico (morado Nu, naranja Didi, etc.)
  String? notas;
  List<PartidaDeudaModelo> historialPartidas; // Registro acumulativo de pagos, cargos y préstamos

  DeudaModelo({
    required this.id,
    required this.tituloOEntidad,
    required this.tipoDeuda,
    required this.montoTotal,
    this.limiteAjustado,
    required this.montoPendiente,
    this.fechaLimitePago,
    this.diaCorte,
    this.colorTarjeta,
    this.notas,
    List<PartidaDeudaModelo>? historialPartidas,
  }) : historialPartidas = historialPartidas ?? [];

  // Getter para verificar si está totalmente saldada
  bool get estaSaldada => montoPendiente <= 0;

  // Límite efectivo a considerar (si ajustó un tope menor, usamos ese)
  double get limiteEfectivo => (limiteAjustado != null && limiteAjustado! > 0)
      ? limiteAjustado!
      : montoTotal;

  // Crédito disponible calculado en base al límite efectivo
  double get creditoDisponible {
    final disponible = limiteEfectivo - montoPendiente;
    return disponible < 0 ? 0.0 : disponible;
  }

  // Porcentaje liquidado o pagado (0.0 a 1.0)
  double get porcentajePagado {
    if (montoTotal <= 0) return 1.0;
    final pagado = montoTotal - montoPendiente;
    return (pagado / montoTotal).clamp(0.0, 1.0);
  }

  // Acumular un nuevo préstamo a esta misma persona
  void acumularNuevoPrestamo({
    required String concepto,
    required double monto,
    required DateTime fecha,
  }) {
    montoTotal += monto;
    montoPendiente += monto;
    historialPartidas.insert(
      0,
      PartidaDeudaModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        concepto: concepto,
        monto: monto,
        fecha: fecha,
        esAbono: false,
      ),
    );
  }

  // Registrar un cargo de compra en la tarjeta de crédito
  void registrarCargoTarjeta({
    required double monto,
    required DateTime fecha,
    required String concepto,
  }) {
    montoPendiente += monto;
    historialPartidas.insert(
      0,
      PartidaDeudaModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        concepto: concepto,
        monto: monto,
        fecha: fecha,
        esAbono: false,
      ),
    );
  }

  // Registrar un pago o abono
  void registrarAbono({
    required double monto,
    required DateTime fecha,
    String concepto = 'Pago / Abono',
  }) {
    montoPendiente -= monto;
    if (montoPendiente < 0) montoPendiente = 0;
    historialPartidas.insert(
      0,
      PartidaDeudaModelo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        concepto: concepto,
        monto: monto,
        fecha: fecha,
        esAbono: true,
      ),
    );
  }

  // Getter de conveniencia para compatibilidad
  String get nombreDeudor => tituloOEntidad;
}
