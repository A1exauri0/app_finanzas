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
import 'servicios/tema_servicio.dart';

// ==========================================
// IMPORTACIONES DE PANTALLAS
// ==========================================
import 'pantallas/navegacion_principal_screen.dart';

// ==========================================
// PUNTO DE ENTRADA PRINCIPAL
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización multiplataforma de SQLite (Android, iOS, Windows, Linux, macOS)
  BaseDatosServicio.inicializarFabricaSQLite();

  // Cargar preferencia guardada del modo de tema
  await TemaServicio.instancia.inicializar();

  runApp(const AppFinanzas());
}

// ==========================================
// WIDGET RAIZ DE LA APLICACION
// ==========================================
class AppFinanzas extends StatelessWidget {
  const AppFinanzas({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaServicio.instancia.temaModoNotifier,
      builder: (context, modoActual, _) {
        return MaterialApp(
          title: 'AppFinanzas',
          debugShowCheckedModeBanner: false,
          themeMode: modoActual,
          theme: ColoresApp.temaClaro(),
          darkTheme: ColoresApp.temaOscuro(),
          home: const NavegacionPrincipalScreen(),
        );
      },
    );
  }
}
