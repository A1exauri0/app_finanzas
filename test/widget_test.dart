// ==========================================
// IMPORTACIONES DE PAQUETES DE TEST
// ==========================================
import 'package:flutter_test/flutter_test.dart';

// ==========================================
// IMPORTACIONES DE LA APLICACION
// ==========================================
import 'package:app_finanzas/main.dart';

void main() {
  testWidgets('Verifica que cargue la pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const AppFinanzas());
    expect(find.text('Mi Resumen Financiero'), findsOneWidget);
  });
}
