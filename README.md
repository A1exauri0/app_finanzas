# AppFinanzas 💰

Aplicación desarrollada en **Flutter** para el control integral de finanzas personales de forma **100% local**: gastos, ingresos, metas de compra, deudas y tarjetas de crédito.

---

## 🚀 Características Actuales

- **Resumen Financiero (Dashboard):** Visualización del balance disponible acumulado, ingresos y egresos mensuales.
- **Botón Flotante Central (+):** Acceso rápido e intuitivo en el centro de la barra inferior para registrar transacciones y pagos al instante.
- **Control Integral de Deudas y Créditos:**
  - 🤝 **Me Deben:** Préstamos otorgados a terceros con seguimiento de cobros y deducción automática del saldo pendiente.
  - 💳 **Debo (Pasivos):** Deudas personales por pagar con control de saldo liquidado.
  - 🏦 **Tarjetas de Crédito:** Registro de saldo a pagar, límites de crédito, días de corte y recordatorios de pago para evitar intereses.
- **Acciones Rápidas:** Registro directo de ingresos, gastos y abonos a tarjetas.
- **Navegación Intuitiva:** Barra inferior dividida en 4 módulos clave con botón central integrado:
  - 🏠 **Inicio:** Vista general y métricas de balance.
  - 🧾 **Movimientos:** Historial y detalle de entradas/salidas.
  - 🎯 **Metas:** Planificación y ahorro para compras.
  - 💳 **Deudas:** Gestión de cuentas por cobrar, cuentas por pagar y tarjetas.

---

## 📁 Estructura del Proyecto

El código fuente sigue una arquitectura modular en `lib/`:

```text
lib/
├── constantes/     # Paleta de colores y estilos visuales (ColoresApp)
├── modelos/        # MovimientoModelo, DeudaModelo (meDeben, debo, tarjetaCredito)
├── componentes/    # BalanceCard, MovimientoItemTile, DeudasResumenCard, NuevoMovimientoModal, NuevaDeudaModal
├── pantallas/      # InicioScreen, MovimientosScreen, MetasScreen, DeudasScreen, NavegacionPrincipalScreen
└── main.dart       # Configuración y punto de entrada
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
