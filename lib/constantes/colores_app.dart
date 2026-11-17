// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// PALETA DE COLORES Y GESTION DE TEMAS
// ==========================================
class ColoresApp {
  // Colores principales de la marca
  static const Color primarioVerde = Color(0xFF00796B);
  static const Color secundarioVerdeClaro = Color(0xFF48A999);

  // Paleta de Fondos
  static const Color fondoClaro = Color(0xFFF7F9FA);
  static const Color fondoOscuro = Color(0xFF0F172A); // Slate 900 elegante

  // Paleta de Tarjetas / Superficies
  static const Color tarjetaClara = Colors.white;
  static const Color tarjetaOscura = Color(0xFF1E293B); // Slate 800
  static const Color tarjetaElevadaClara = Color(0xFFF1F5F9);
  static const Color tarjetaElevadaOscura = Color(0xFF334155); // Slate 700

  // Colores para estados financieros
  static const Color ingresoVerde = Color(0xFF2E7D32);
  static const Color gastoRojo = Color(0xFFC62828);
  static const Color inversionAzul = Color(0xFF1565C0);
  static const Color metaNaranja = Color(0xFFEF6C00);

  // Paleta de Textos
  static const Color textoPrincipalClaro = Color(0xFF263238);
  static const Color textoSecundarioClaro = Color(0xFF78909C);
  static const Color textoPrincipalOscuro = Color(0xFFF8FAFC);
  static const Color textoSecundarioOscuro = Color(0xFF94A3B8);

  // Bordes y separadores
  static const Color bordeClaro = Color(0xFFE2E8F0);
  static const Color bordeOscuro = Color(0xFF334155);

  // Compatibilidad hacia atrás con constantes estáticas
  static const Color tarjetaFondo = tarjetaClara;
  static const Color textoPrincipal = textoPrincipalClaro;
  static const Color textoSecundario = textoSecundarioClaro;

  // ==========================================
  // METODOS DE CONSULTA ADAPTABLE AL CONTEXTO
  // ==========================================
  static bool esOscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color fondo(BuildContext context) =>
      esOscuro(context) ? fondoOscuro : fondoClaro;

  static Color tarjeta(BuildContext context) =>
      esOscuro(context) ? tarjetaOscura : tarjetaClara;

  static Color tarjetaElevada(BuildContext context) =>
      esOscuro(context) ? tarjetaElevadaOscura : tarjetaElevadaClara;

  static Color texto(BuildContext context) =>
      esOscuro(context) ? textoPrincipalOscuro : textoPrincipalClaro;

  static Color subtexto(BuildContext context) =>
      esOscuro(context) ? textoSecundarioOscuro : textoSecundarioClaro;

  static Color borde(BuildContext context) =>
      esOscuro(context) ? bordeOscuro : bordeClaro;

  // ==========================================
  // CONSTRUCTORES DE THEMEDATA (CLARO / OSCURO)
  // ==========================================
  static ThemeData temaClaro() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: fondoClaro,
      cardColor: tarjetaClara,
      canvasColor: fondoClaro,
      dividerColor: bordeClaro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarioVerde,
        primary: primarioVerde,
        secondary: secundarioVerdeClaro,
        surface: tarjetaClara,
        onSurface: textoPrincipalClaro,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondoClaro,
        foregroundColor: textoPrincipalClaro,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: tarjetaClara,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tarjetaClara,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tarjetaClara,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: tarjetaClara,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static ThemeData temaOscuro() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fondoOscuro,
      cardColor: tarjetaOscura,
      canvasColor: fondoOscuro,
      dividerColor: bordeOscuro,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarioVerde,
        primary: secundarioVerdeClaro,
        secondary: primarioVerde,
        surface: tarjetaOscura,
        onSurface: textoPrincipalOscuro,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondoOscuro,
        foregroundColor: textoPrincipalOscuro,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: tarjetaOscura,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tarjetaOscura,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tarjetaOscura,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: tarjetaOscura,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
