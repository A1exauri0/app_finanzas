// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE CONSTANTES Y ESTILOS
// ==========================================
import '../constantes/colores_app.dart';

// ==========================================
// IMPORTACIONES DE PANTALLAS
// ==========================================
import 'inicio_screen.dart';
import 'movimientos_screen.dart';
import 'metas_screen.dart';
import 'inversiones_screen.dart';

// ==========================================
// PANTALLA CONTENEDORA: NAVEGACION PRINCIPAL
// ==========================================
class NavegacionPrincipalScreen extends StatefulWidget {
  const NavegacionPrincipalScreen({super.key});

  @override
  State<NavegacionPrincipalScreen> createState() => _NavegacionPrincipalScreenState();
}

class _NavegacionPrincipalScreenState extends State<NavegacionPrincipalScreen> {
  // Estado local para la pestaña seleccionada
  int _indicePestanaActual = 0;

  // Lista de pantallas asociadas a cada pestaña
  final List<Widget> _pantallasApp = const [
    InicioScreen(),
    MovimientosScreen(),
    MetasScreen(),
    InversionesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallasApp[_indicePestanaActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indicePestanaActual,
        onDestinationSelected: (int nuevoIndice) {
          setState(() {
            _indicePestanaActual = nuevoIndice;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: ColoresApp.primarioVerde.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: ColoresApp.primarioVerde),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: ColoresApp.primarioVerde),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded, color: ColoresApp.primarioVerde),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up_rounded, color: ColoresApp.primarioVerde),
            label: 'Inversiones',
          ),
        ],
      ),
    );
  }
}
