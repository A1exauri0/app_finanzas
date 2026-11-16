// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// PANTALLA: PORTAFOLIO DE INVERSIONES
// ==========================================
class InversionesScreen extends StatelessWidget {
  const InversionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoClaro,
      appBar: AppBar(
        title: const Text('Mis Inversiones'),
        backgroundColor: ColoresApp.fondoClaro,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Aquí visualizaremos tus activos, rendimientos y aportaciones.',
          style: TextStyle(color: ColoresApp.textoSecundario),
        ),
      ),
    );
  }
}
