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
}
