// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// PANTALLA: MOVIMIENTOS FINANCIEROS
// ==========================================
class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoClaro,
      appBar: AppBar(
        title: const Text('Movimientos'),
        backgroundColor: ColoresApp.fondoClaro,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Aquí listaremos todos los ingresos y gastos detallados.',
          style: TextStyle(color: ColoresApp.textoSecundario),
        ),
      ),
    );
  }
}
