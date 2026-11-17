// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// IMPORTACIONES DE SERVICIOS
// ==========================================
import 'base_datos_servicio.dart';

// ==========================================
// SERVICIO DE GESTION DE TEMA (CLARO / OSCURO)
// ==========================================
class TemaServicio {
  static final TemaServicio instancia = TemaServicio._iniciar();

  // Notificador reactivo del modo de tema activo
  final ValueNotifier<ThemeMode> temaModoNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  TemaServicio._iniciar();

  // Carga inicial del tema guardado en SQLite
  Future<void> inicializar() async {
    try {
      final valorGuardado =
          await BaseDatosServicio.instancia.obtenerConfiguracion('tema_modo');
      if (valorGuardado == 'oscuro') {
        temaModoNotifier.value = ThemeMode.dark;
      } else if (valorGuardado == 'claro') {
        temaModoNotifier.value = ThemeMode.light;
      } else {
        temaModoNotifier.value = ThemeMode.system;
      }
    } catch (_) {
      // Si la base de datos aún no está disponible, mantenemos el tema del sistema
      temaModoNotifier.value = ThemeMode.system;
    }
  }

  // Comprueba si el tema resultante actual es oscuro
  bool esModoOscuroActivo(BuildContext context) {
    if (temaModoNotifier.value == ThemeMode.dark) return true;
    if (temaModoNotifier.value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  // Alterna entre modo claro y oscuro
  Future<void> alternarTema(BuildContext context) async {
    final bool actualmenteOscuro = esModoOscuroActivo(context);
    final nuevoModo = actualmenteOscuro ? ThemeMode.light : ThemeMode.dark;
    await cambiarModo(nuevoModo);
  }

  // Cambia el modo de tema y lo persiste en la base de datos local
  Future<void> cambiarModo(ThemeMode nuevoModo) async {
    temaModoNotifier.value = nuevoModo;
    try {
      final String valorTexto = nuevoModo == ThemeMode.dark
          ? 'oscuro'
          : nuevoModo == ThemeMode.light
              ? 'claro'
              : 'sistema';
      await BaseDatosServicio.instancia
          .guardarConfiguracion('tema_modo', valorTexto);
    } catch (_) {
      // Ignoramos errores de persistencia si se ejecuta en pruebas
    }
  }
}
