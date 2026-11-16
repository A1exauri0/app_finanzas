// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import 'constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import 'servicios/base_datos_servicio.dart';

// ==========================================
// IMPORTACIONES DE PANTALLAS
// ==========================================
import 'pantallas/navegacion_principal_screen.dart';

// ==========================================
// PUNTO DE ENTRADA PRINCIPAL
// ==========================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización multiplataforma de SQLite (Android, iOS, Windows, Linux, macOS)
  BaseDatosServicio.inicializarFabricaSQLite();

  runApp(const AppFinanzas());
}

// ==========================================
// WIDGET RAIZ DE LA APLICACION
// ==========================================
class AppFinanzas extends StatelessWidget {
  const AppFinanzas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppFinanzas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: ColoresApp.fondoClaro,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColoresApp.primarioVerde,
          primary: ColoresApp.primarioVerde,
        ),
      ),
      home: const NavegacionPrincipalScreen(),
    );
  }
}
