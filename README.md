# AppFinanzas 💰

Aplicación desarrollada en **Flutter** para el control integral de finanzas personales de forma **100% local**: gastos, ingresos, metas de compra y portafolio de inversiones.

---

## 🚀 Características Actuales

- **Resumen Financiero (Dashboard):** Visualización del balance disponible acumulado, ingresos y egresos mensuales.
- **Acciones Rápidas:** Accesos directos para registrar ingresos, gastos, metas e inversiones.
- **Historial Reciente:** Listado visual de las últimas transacciones registradas.
- **Navegación Intuitiva:** Barra inferior (Material 3 NavigationBar) dividida en 4 módulos:
  - 🏠 **Inicio:** Vista general y métricas clave.
  - 🧾 **Movimientos:** Control detallado de flujo de caja (ingresos vs gastos).
  - 🎯 **Metas:** Planificación y seguimiento a objetivos de compra.
  - 📈 **Inversiones:** Registro de activos y rendimientos.
- **Diseño Moderno:** Interfaz limpia basada en Material 3, adaptable a Android y Windows Desktop.

---

## 📁 Estructura del Proyecto

El código fuente sigue una arquitectura modular en `lib/`:

```text
lib/
├── constantes/     # Paleta de colores y estilos visuales (ColoresApp)
├── modelos/        # Modelos de datos de la aplicación (MovimientoModelo)
├── componentes/    # Widgets visuales reutilizables (BalanceCard, MovimientoItemTile)
├── pantallas/      # Vistas completas y barra de navegación principal
└── main.dart       # Punto de entrada y configuración del tema
```

---

## 🛠️ Requisitos y Tecnologías

- **Flutter SDK:** 3.38.5+
- **Dart SDK:** 3.10.4+
- **Plataformas compatibles:** Android, Windows Desktop (e iOS con entorno macOS).

---

## 💻 Instrucciones de Ejecución

1. Clona el repositorio o abre el directorio del proyecto:
   ```bash
   cd app_finanzas
   ```

2. Obtén las dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecuta la aplicación:
   - **En Windows Desktop:**
     ```bash
     flutter run -d windows
     ```
   - **En Android (emulador o dispositivo físico):**
     ```bash
     flutter run -d android
     ```
