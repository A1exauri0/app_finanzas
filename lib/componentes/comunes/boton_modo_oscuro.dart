// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y SERVICIOS
// ==========================================
import '../../constantes/colores_app.dart';
import '../../servicios/tema_servicio.dart';

// ==========================================
// COMPONENTE VISUAL: BOTON GLOBAL DE MODO OSCURO
// ==========================================
class BotonModoOscuro extends StatelessWidget {
  const BotonModoOscuro({super.key});

  @override
  Widget build(BuildContext context) {
    final bool esOscuro = ColoresApp.esOscuro(context);

    return IconButton(
      tooltip: esOscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      icon: Icon(
        esOscuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: esOscuro ? Colors.amber : ColoresApp.texto(context),
      ),
      onPressed: () => TemaServicio.instancia.alternarTema(context),
    );
  }
}
