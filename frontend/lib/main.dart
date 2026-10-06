import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/fcm_service.dart';
import 'core/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FcmService.initialize();
  } catch (_) {}
  try {
    await Hive.initFlutter();
    await OfflineSyncService().initialize();
  } catch (_) {}
  runApp(
    ProviderScope(
      child: const CivilOSApp(),
    ),
  );
}

class CivilOSApp extends ConsumerWidget {
  const CivilOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CivilOS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: CivilTheme.lightTheme,
      darkTheme: CivilTheme.darkTheme,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      routerConfig: goRouter,
    );
  }
}
