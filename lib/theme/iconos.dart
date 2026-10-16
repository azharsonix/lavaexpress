import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Iconos de la aplicación (set Lucide, trazo lineal).
/// Todas las pantallas toman los iconos de aquí para mantener un solo estilo.
abstract final class Iconos {
  // Marca
  static const IconData marca = LucideIcons.washingMachine;

  // Navegación
  static const IconData inicio = LucideIcons.house;
  static const IconData pedidos = LucideIcons.receiptText;
  static const IconData perfil = LucideIcons.user;
  static const IconData agregar = LucideIcons.plus;
  static const IconData cerrar = LucideIcons.x;
  static const IconData regresar = LucideIcons.arrowLeft;
  static const IconData siguiente = LucideIcons.chevronRight;
  static const IconData salir = LucideIcons.logOut;
  static const IconData buscar = LucideIcons.search;

  // Formularios
  static const IconData correo = LucideIcons.mail;
  static const IconData contrasena = LucideIcons.lock;
  static const IconData mostrar = LucideIcons.eye;
  static const IconData ocultar = LucideIcons.eyeOff;
  static const IconData nombre = LucideIcons.user;
  static const IconData telefono = LucideIcons.phone;
  static const IconData registro = LucideIcons.userPlus;
  static const IconData guardar = LucideIcons.save;
  static const IconData editar = LucideIcons.pencil;

  // Pedido
  static const IconData servicio = LucideIcons.shirt;
  static const IconData tarifa = LucideIcons.tag;
  static const IconData peso = LucideIcons.scale;
  static const IconData total = LucideIcons.banknote;
  static const IconData calculo = LucideIcons.calculator;
  static const IconData fecha = LucideIcons.calendar;
  static const IconData horario = LucideIcons.clock;
  static const IconData direccion = LucideIcons.mapPin;
  static const IconData domicilio = LucideIcons.truck;
  static const IconData lavanderia = LucideIcons.store;
  static const IconData cliente = LucideIcons.idCard;
  static const IconData lleno = LucideIcons.ban;

  // Estados de la app
  static const IconData info = LucideIcons.info;
  static const IconData exito = LucideIcons.circleCheck;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData vacio = LucideIcons.inbox;
  static const IconData sinConexion = LucideIcons.cloudOff;
  static const IconData noEncontrado = LucideIcons.searchX;
  static const IconData seleccionar = LucideIcons.mousePointerClick;
  static const IconData historial = LucideIcons.history;
  static const IconData preferencias = LucideIcons.settings;
  static const IconData ubicacion = LucideIcons.locateFixed;
  static const IconData mapa = LucideIcons.map;
  static const IconData enlace = LucideIcons.externalLink;
}
