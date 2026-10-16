import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/preferencias.dart';
import 'theme/app_theme.dart';
import 'widgets/aviso_conexion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conecta la app con el proyecto de Firebase LavaExpress
  // (en paralelo con la carga de formatos de fecha).
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('es_MX'),
    Preferencias.instance.cargar(),
  ]);
  // Caché local: al volver a abrir la app los datos aparecen de inmediato
  // y después se actualizan desde la nube. En web se comparte entre pestañas.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    webPersistentTabManager: WebPersistentMultipleTabManager(),
  );
  runApp(const LavaExpressApp());
}

class LavaExpressApp extends StatelessWidget {
  const LavaExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Preferencias.instance.tema,
      builder: (context, tema, _) => MaterialApp(
        title: 'LavaExpress',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        darkTheme: AppTheme.oscuro(),
        themeMode: tema,
        builder: (context, child) => AvisoConexion(child: child!),
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthGate(),
      ),
    );
  }
}
