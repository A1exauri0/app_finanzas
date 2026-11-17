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
    expect(find.textContaining('Dinero disponible'), findsOneWidget);
    expect(find.text('Aún no hay movimientos registrados'), findsOneWidget);
  });

  testWidgets('Verifica navegación al Panel de Finanzas y Gráficas', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    await tester.pumpAndSettle();

    final botonGraficas = find.text('Gráficas');
    expect(botonGraficas, findsOneWidget);
    await tester.tap(botonGraficas);
    await tester.pumpAndSettle();

    expect(find.text('Análisis Financiero & Gráficas'), findsOneWidget);
    expect(find.text('DINERO DISPONIBLE HOY'), findsOneWidget);
    expect(find.text('No hay gastos registrados para graficar.'), findsOneWidget);
    expect(find.text('Comparativa de Flujo de Dinero'), findsOneWidget);
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

    await tester.tap(find.text('Nueva Meta'));
    await tester.pumpAndSettle();

    final camposMeta = find.byType(TextFormField);
    await tester.enterText(camposMeta.first, 'Viaje');
    await tester.enterText(camposMeta.at(1), '500'); // objetivo
    await tester.enterText(camposMeta.at(2), '200'); // ahorrado inicial
    await tester.tap(find.text('Crear Meta de Compra'));
    await tester.pumpAndSettle();

    // 3. Regresamos a Inicio y verificamos que el disponible ahora sea \$800.00
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

    // 5. Regresamos a Inicio y verificamos que el disponible subió a \$900.00
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('\$900.00'), findsWidgets);

    // Drenamos los temporizadores internos de sqflite
    await tester.pump(const Duration(seconds: 12));
  });
}
