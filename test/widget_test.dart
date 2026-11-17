// ==========================================
// IMPORTACIONES DE PAQUETES DE TEST
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ==========================================
// IMPORTACIONES DE LA APLICACION Y SERVICIOS
// ==========================================
import 'package:app_finanzas/main.dart';
import 'package:app_finanzas/servicios/base_datos_servicio.dart';
import 'package:app_finanzas/servicios/tema_servicio.dart';
import 'package:app_finanzas/componentes/graficas/grafica_dona_categorias.dart';
import 'package:app_finanzas/componentes/comunes/boton_modo_oscuro.dart';





void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    BaseDatosServicio.rutaPersonalizada = inMemoryDatabasePath;
  });

  tearDown(() async {
    await BaseDatosServicio.instancia.vaciarBaseDatos();
  });

  testWidgets('Verifica que cargue la pantalla principal limpia con base de datos', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    expect(find.text('Mi Resumen Financiero'), findsOneWidget);
    expect(find.text('Balance Disponible'), findsOneWidget);
    expect(find.text('Aún no hay movimientos registrados'), findsOneWidget);
    // Verifica que se eliminó la sección de Acciones Rápidas
    expect(find.text('Acciones Rápidas'), findsNothing);
    // Verifica presencia del botón global de modo oscuro en el AppBar
    expect(find.byType(BotonModoOscuro), findsOneWidget);
  });

  testWidgets('Verifica que las gráficas y análisis financiero se muestren directamente en Inicio', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    expect(find.text('Capacidad de Gasto & Compromiso'), findsOneWidget);
    expect(find.text('No hay gastos registrados para graficar.'), findsOneWidget);
    // Verifica que se removieron las cards de comparativa y recomendaciones
    expect(find.text('Comparativa de Flujo de Dinero'), findsNothing);
    expect(find.text('Recomendaciones del Asesor'), findsNothing);
  });

  testWidgets('Verifica alerta de sobregiro al intentar gastar más de lo disponible', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    final botonAgregar = find.byType(FloatingActionButton);
    expect(botonAgregar, findsOneWidget);
    await tester.tap(botonAgregar);
    await tester.pumpAndSettle();

    expect(find.text('Registrar Gasto'), findsOneWidget);

    final camposTexto = find.byType(TextFormField);
    await tester.enterText(camposTexto.first, '999999');
    await tester.pumpAndSettle();

    expect(find.text('¡Gastas más de lo que tienes!'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(tester.element(find.text('Registrar Gasto'))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('Verifica navegación a Movimientos y presencia de filtros en limpio', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    final tabMovimientos = find.text('Movimientos');
    expect(tabMovimientos, findsOneWidget);
    await tester.tap(tabMovimientos);
    await tester.pumpAndSettle();

    expect(find.text('Historial de Movimientos'), findsOneWidget);
    expect(find.text('Ingresos'), findsWidgets);
    expect(find.text('Gastos'), findsWidgets);
    expect(find.text('Con Tarjeta'), findsOneWidget);
    expect(find.text('No hay movimientos en esta vista'), findsOneWidget);
  });

  testWidgets('Verifica navegación a Metas en limpio sin desbordamientos', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    final tabMetas = find.text('Metas');
    expect(tabMetas, findsOneWidget);
    await tester.tap(tabMetas);
    await tester.pumpAndSettle();

    expect(find.text('Objetivos de Compra'), findsOneWidget);
    expect(find.text('No hay metas en esta categoría.'), findsOneWidget);
  });

  testWidgets('Verifica alternar Modo Oscuro y persistencia de tema', (WidgetTester tester) async {
    TemaServicio.instancia.cambiarModo(ThemeMode.light);
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    // Comprobamos el icono inicial de cambio de tema (luna en modo claro)
    final botonTema = find.byIcon(Icons.dark_mode_rounded);
    expect(botonTema, findsOneWidget);

    // Tocamos el botón de alternar tema
    await tester.tap(botonTema);
    await tester.pumpAndSettle();

    // Verificamos que ahora se muestre el icono de sol (modo oscuro activo)
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(TemaServicio.instancia.temaModoNotifier.value, ThemeMode.dark);

    // Tocamos de nuevo para volver a modo claro
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(TemaServicio.instancia.temaModoNotifier.value, ThemeMode.light);

    // Drenamos los temporizadores de bloqueo de transacciones de SQLite
    await tester.pump(const Duration(seconds: 12));
  });

  testWidgets('Verifica gráfica de dona de gastos por categoría', (WidgetTester tester) async {
    final segmentos = [
      SegmentoCategoriaDona(
        nombre: 'Comida',
        monto: 850.0,
        color: Colors.red,
        icono: Icons.shopping_cart_rounded,
      ),
      SegmentoCategoriaDona(
        nombre: 'Transporte',
        monto: 500.0,
        color: Colors.blue,
        icono: Icons.directions_car_rounded,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GraficaDonaCategoriasCard(
              segmentos: segmentos,
              totalGastos: 1350.0,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificamos que la gráfica de dona esté visible con sus categorías
    expect(find.text('Distribución de Gastos'), findsOneWidget);
    expect(find.text('Total Gastos'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
  });

  testWidgets('Verifica que abonar y retirar en Metas impacte el dinero disponible', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    // 1. Ingresamos saldo inicial (\$1000)
    final botonAgregar = find.byType(FloatingActionButton);
    await tester.tap(botonAgregar);
    await tester.pumpAndSettle();

    // Cambiar a ingreso
    await tester.tap(find.text('Ingreso').last);
    await tester.pumpAndSettle();

    // Ingresar monto 1000
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.first, '1000');
    await tester.enterText(campos.at(1), 'Sueldo');
    await tester.tap(find.text('Guardar Movimiento'));
    await tester.pumpAndSettle();

    // Verificamos que el balance muestre \$1000.00
    expect(find.text('\$1000.00'), findsWidgets);

    // 2. Navegamos a Metas y creamos una nueva meta con \$200 ahorrados
    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final camposMeta = find.byType(TextFormField);
    await tester.enterText(camposMeta.first, 'Viaje');
    await tester.enterText(camposMeta.at(1), '500'); // objetivo
    await tester.enterText(camposMeta.at(2), '200'); // ahorrado inicial
    await tester.tap(find.text('Crear Meta de Compra'));
    await tester.pumpAndSettle();

    // 3. Volvemos a Inicio y verificamos disponible
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('\$800.00'), findsWidgets);

    // 4. Volvemos a Metas y retiramos \$100 de la meta
    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();

    final campoRetiro = find.byType(TextField);
    await tester.enterText(campoRetiro.last, '100');
    await tester.tap(find.text('Confirmar Retiro'));
    await tester.pumpAndSettle();

    // 5. Volvemos a Inicio y verificamos que el disponible subió a \$900.00
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('\$900.00'), findsWidgets);

    // Drenamos los temporizadores internos de sqflite
    await tester.pump(const Duration(seconds: 12));
  });

  testWidgets('Verifica registro y pago en 1 toque de gastos fijos mensuales', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    // 1. Ingresamos saldo inicial (\$1000)
    final botonAgregar = find.byType(FloatingActionButton);
    await tester.tap(botonAgregar);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingreso').last);
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.first, '1000');
    await tester.enterText(campos.at(1), 'Sueldo');
    await tester.tap(find.text('Guardar Movimiento'));
    await tester.pumpAndSettle();

    // 2. Navegamos a la pestaña Deudas y seleccionamos la pestaña Gastos Fijos
    await tester.tap(find.text('Deudas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gastos Fijos'));
    await tester.pumpAndSettle();

    // Verificamos presencia de Gastos Fijos del Mes
    expect(find.text('Gastos Fijos del Mes'), findsOneWidget);

    // Tocamos botón "Agregar" en Gastos Fijos
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo Gasto Fijo o Mensual'), findsOneWidget);

    // Ingresamos el nombre y monto directamente en los campos de texto
    final camposGastoFijo = find.byType(TextFormField);
    await tester.enterText(camposGastoFijo.first, 'Spotify');
    await tester.enterText(camposGastoFijo.at(1), '129');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar Gasto Fijo'));
    await tester.pumpAndSettle();

    // Verificamos que aparezca Spotify en la lista
    expect(find.text('Spotify'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);

    // 3. Pagamos Spotify en 1 toque
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();

    // Verificamos que ahora diga 'Listo'
    expect(find.text('Listo'), findsOneWidget);

    // 4. Volvemos a Inicio y verificamos que el dinero disponible haya descontado \$129 (1000 - 129 = 871.00)
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('\$871.00'), findsWidgets);

    // Drenamos los temporizadores internos de sqflite
    await tester.pump(const Duration(seconds: 12));
  });

  testWidgets('Verifica responsividad en pantalla compacta (320px) sin errores de overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    // Verificamos que los elementos de navegación y resumen carguen sin desbordamiento
    expect(find.text('Mi Resumen Financiero'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Deudas'), findsOneWidget);

    // Abrimos ventana modal tipo diálogo de Nuevo Movimiento desde el botón (+) y la cerramos con el botón X
    final botonCentral = find.byType(FloatingActionButton);
    await tester.tap(botonCentral);
    await tester.pumpAndSettle();
    expect(find.text('Registrar Gasto'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Registrar Gasto'), findsNothing);

    // Navegamos a Metas, abrimos el diálogo de Nueva Meta y la cerramos con el botón X
    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();
    expect(find.text('Objetivos de Compra'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nueva Meta de Compra o Ahorro'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nueva Meta de Compra o Ahorro'), findsNothing);

    // Drenamos temporizadores de sqflite
    await tester.pump(const Duration(seconds: 12));
  });
}
