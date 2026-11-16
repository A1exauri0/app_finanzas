// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// PANTALLA: METAS Y OBJETIVOS DE COMPRA
// ==========================================
class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondoClaro,
      appBar: AppBar(
        title: const Text('Objetivos de Compra'),
        backgroundColor: ColoresApp.fondoClaro,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Aquí gestionaremos tus metas de ahorro y compras planificadas.',
          style: TextStyle(color: ColoresApp.textoSecundario),
        ),
      ),
    );
  }
}
