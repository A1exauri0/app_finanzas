// ==========================================
// IMPORTACIONES DE PAQUETES DE FLUTTER
// ==========================================
import 'package:flutter/material.dart';

// ==========================================
// MODELO AUXILIAR PARA ENTIDADES BANCARIAS
// ==========================================
class BancoItem {
  final String nombre;
  final Color color;

  const BancoItem({
    required this.nombre,
    required this.color,
  });
}

// ==========================================
// CATALOGO GENERAL DE BANCOS Y FINTECHS
// ==========================================
class CatalogoBancos {
  static const List<BancoItem> listaBancos = [
    BancoItem(nombre: 'Nu México', color: Color(0xFF820AD1)),
    BancoItem(nombre: 'Didi Card', color: Color(0xFFFF7700)),
    BancoItem(nombre: 'Mercado Pago', color: Color(0xFF009EE3)),
    BancoItem(nombre: 'BBVA', color: Color(0xFF004481)),
    BancoItem(nombre: 'Citibanamex', color: Color(0xFF002D72)),
    BancoItem(nombre: 'Santander', color: Color(0xFFEC0000)),
    BancoItem(nombre: 'Banorte', color: Color(0xFFEB0029)),
    BancoItem(nombre: 'HSBC', color: Color(0xFFDB0011)),
    BancoItem(nombre: 'Scotiabank', color: Color(0xFFEC111A)),
    BancoItem(nombre: 'Hey Banco', color: Color(0xFF1A1A1A)),
    BancoItem(nombre: 'Stori', color: Color(0xFF00A86B)),
    BancoItem(nombre: 'Klar', color: Color(0xFF00897B)),
    BancoItem(nombre: 'RappiCard', color: Color(0xFFFF441F)),
    BancoItem(nombre: 'Banco Azteca', color: Color(0xFF006837)),
    BancoItem(nombre: 'Inbursa', color: Color(0xFF003B70)),
    BancoItem(nombre: 'Liverpool', color: Color(0xFFE6007E)),
  ];

  static const BancoItem otroBanco = BancoItem(
    nombre: 'Otro Banco / Tarjeta',
    color: Color(0xFF455A64),
  );
}
