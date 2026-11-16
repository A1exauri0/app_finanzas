// ==========================================
// IMPORTACIONES DE PAQUETES DE TEST
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ==========================================
// IMPORTACIONES DE LA APLICACION
// ==========================================
import 'package:app_finanzas/main.dart';

void main() {
  testWidgets('Verifica que cargue la pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    expect(find.text('Mi Resumen Financiero'), findsOneWidget);
    expect(find.textContaining('Dinero disponible'), findsOneWidget);
  });

  testWidgets('Verifica navegación al Panel de Finanzas y Gráficas', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());

    // Pulsamos el botón de Gráficas en el encabezado
    final botonGraficas = find.text('Gráficas');
    expect(botonGraficas, findsOneWidget);
    await tester.tap(botonGraficas);
    await tester.pumpAndSettle();

    // Verificamos que cargue el análisis financiero y sus secciones
    expect(find.text('Análisis Financiero & Gráficas'), findsOneWidget);
    expect(find.text('DINERO DISPONIBLE HOY'), findsOneWidget);
    expect(find.text('Distribución de Gastos'), findsOneWidget);
    expect(find.text('Comparativa de Flujo de Dinero'), findsOneWidget);
  });

  testWidgets('Verifica alerta de sobregiro al intentar gastar más de lo disponible', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());

    // Pulsamos el botón (+) central para registrar movimiento
    final botonAgregar = find.byType(FloatingActionButton);
    expect(botonAgregar, findsOneWidget);
    await tester.tap(botonAgregar);
    await tester.pumpAndSettle();

    // Verificamos que abra el modal de registro de gasto
    expect(find.text('Registrar Gasto'), findsOneWidget);

    // Escribimos un monto muy alto que sobrepase el disponible (ej. 999999)
    final camposTexto = find.byType(TextFormField);
    await tester.enterText(camposTexto.first, '999999');
    await tester.pumpAndSettle();

    // Verificamos que aparezca la alerta de sobregiro en pantalla
    expect(find.text('¡Gastas más de lo que tienes!'), findsOneWidget);
  });

  testWidgets('Verifica navegación a Movimientos y presencia de filtros', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());

    // Pulsamos en la pestaña de Movimientos
    final tabMovimientos = find.text('Movimientos');
    expect(tabMovimientos, findsOneWidget);
    await tester.tap(tabMovimientos);
    await tester.pumpAndSettle();

    // Verificamos elementos del módulo de Movimientos
    expect(find.text('Historial de Movimientos'), findsOneWidget);
    expect(find.text('Ingresos'), findsWidgets);
    expect(find.text('Gastos'), findsWidgets);
    expect(find.text('Con Tarjeta'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Verifica navegación a Metas sin desbordamientos de pantalla', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());

    // Pulsamos en la pestaña de Metas
    final tabMetas = find.text('Metas');
    expect(tabMetas, findsOneWidget);
    await tester.tap(tabMetas);
    await tester.pumpAndSettle();

    // Verificamos que carguen las metas correctamente
    expect(find.text('Objetivos de Compra'), findsOneWidget);
    expect(find.text('Laptop de Trabajo'), findsOneWidget);
  });
}
